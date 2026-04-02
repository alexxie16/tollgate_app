import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/providers/service_providers.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/tollgate/constants/tollgate_constants.dart';
import '../../../../domain/tollgate/models/tollgate_info.dart';
import '../../../../domain/tollgate/models/tollgate_payment_response.dart';
import '../../../../domain/wifi/models/wifi_connection_info.dart';
import '../../../../domain/wifi/models/wifi_network.dart';
import '../../wallet/providers/local_ecash_providers.dart';
import '../../wifi/providers/connect_to_network_provider.dart';
import '../../wifi/providers/current_connection_state_stream_provider.dart';

class TollgateConnectionResult {
  const TollgateConnectionResult({
    required this.connectionInfo,
    required this.tollgateInfo,
  });

  final WifiConnectionInfo connectionInfo;
  final TollGateInfo tollgateInfo;
}

class TollgateTopUpResult {
  const TollgateTopUpResult({
    required this.token,
    required this.paymentResponse,
    required this.amountSats,
  });

  final Token token;
  final TollGatePaymentResponse paymentResponse;
  final int amountSats;
}

class TollgateInteractor {
  TollgateInteractor(this.ref);

  final WidgetRef ref;

  Future<Result<TollgateConnectionResult, String>> connectAndLoadPricing(
    WiFiNetwork network, {
    String? password,
  }) async {
    final connectResult = await ref.read(
      connectToNetworkProvider(network, password: password).future,
    );

    switch (connectResult) {
      case Failure(failure: final failure):
        return Result.failure(failure.toString());
      case Ok():
        break;
    }

    final wifiService = ref.read(wifiServiceProvider);
    final tollgateService = ref.read(tollgateServiceProvider);
    String lastError =
        'Connected to ${network.ssid}, but TollGate pricing was not reachable.';

    for (var attempt = 0; attempt < 6; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(seconds: 2));
      }

      final connectionResult = await wifiService.getCurrentConnection();
      switch (connectionResult) {
        case Failure(failure: final failure):
          lastError = failure.toString();
          continue;
        case Ok(value: final connectionInfo):
          if (connectionInfo == null) {
            lastError =
                'Waiting for the device to finish joining ${network.ssid}.';
            continue;
          }

          final connectedSsid = connectionInfo.cleanSsid;
          final isExpectedNetwork = connectedSsid == network.ssid ||
              (connectedSsid != null && looksLikeTollGateSsid(connectedSsid));
          if (!isExpectedNetwork) {
            lastError =
                'The device is still on ${connectedSsid ?? 'another network'}.';
            continue;
          }

          final tollgateInfoResult = await tollgateService.getTollgateInfo(
            routerIp: kTollgateRouterIp,
          );

          switch (tollgateInfoResult) {
            case Ok(value: final tollgateInfo):
              ref.invalidate(currentConnectionStateStreamProvider);
              return Result.ok(
                TollgateConnectionResult(
                  connectionInfo: connectionInfo,
                  tollgateInfo: tollgateInfo,
                ),
              );
            case Failure(failure: final failure):
              lastError = failure.message ??
                  'Connected to ${network.ssid}, but TollGate pricing was not reachable.';
          }
      }
    }

    return Result.failure(lastError);
  }

  Future<Result<TollgateTopUpResult, String>> topUp({
    required TollGateInfo tollgateInfo,
    required int amountSats,
    String? authToken,
  }) async {
    if (amountSats <= 0) {
      return Result.failure('Enter an amount greater than 0 sats.');
    }

    final swappedToken =
        await ref.read(swappedEcashLocalTokenStreamProvider.future);
    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    final localToken = swappedToken ?? regularToken;
    if (localToken == null) {
      return Result.failure(
        'No local eCash token is available. Receive a token into the app before buying TollGate access offline.',
      );
    }

    if (localToken.amount < BigInt.from(amountSats)) {
      return Result.failure(
        'The stored local eCash token only has ${localToken.amount} sats, but this selection needs $amountSats sats.',
      );
    }

    late final SplitTokenResult splitResult;
    try {
      splitResult = splitTokenExact(
        token: localToken,
        amount: BigInt.from(amountSats),
      );
    } catch (_) {
      return Result.failure(
        'The active local eCash token cannot be split exactly into $amountSats sats offline. Swap your regular eCash into swapped eCash first from the wallet page.',
      );
    }

    final token = splitResult.selected;

    final paymentResult =
        await ref.read(tollgateServiceProvider).submitEcashToken(
              cashuToken: token.encoded,
              authToken: authToken,
            );

    switch (paymentResult) {
      case Ok(value: final paymentResponse):
        final remainder = splitResult.remainder;
        if (swappedToken != null) {
          if (remainder == null) {
            await ref.read(clearSwappedEcashProvider.future);
          } else {
            await ref.read(storeSwappedEcashProvider(remainder.encoded).future);
          }
        } else {
          if (remainder == null) {
            await ref.read(clearLocalEcashProvider.future);
          } else {
            await ref.read(storeLocalEcashProvider(remainder.encoded).future);
          }
        }
        return Result.ok(
          TollgateTopUpResult(
            token: token,
            paymentResponse: paymentResponse,
            amountSats: token.amount.toInt(),
          ),
        );
      case Failure(failure: final failure):
        return Result.failure(failure.message);
    }
  }
}
