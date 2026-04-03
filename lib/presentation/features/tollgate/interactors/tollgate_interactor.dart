import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/providers/service_providers.dart';
import '../../../../core/result/result.dart';
import '../../../../data/local/tollgate_payment_history_storage.dart';
import '../../../../domain/tollgate/constants/tollgate_constants.dart';
import '../../../../domain/tollgate/models/tollgate_info.dart';
import '../../../../domain/tollgate/models/tollgate_payment_response.dart';
import '../../../../domain/wifi/models/wifi_connection_info.dart';
import '../../../../domain/wifi/models/wifi_network.dart';
import '../../wallet/providers/local_ecash_providers.dart';
import '../../wallet/providers/wallet_history_provider.dart';
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
    String? ssid,
    String? dataLabel,
  }) async {
    if (amountSats <= 0) {
      return Result.failure('Enter an amount greater than 0 sats.');
    }

    final swappedOneSatTokens =
        await ref.read(swappedEcashOneSatTokensProvider.future);
    final swappedPoolTotal = swappedOneSatTokens.fold<BigInt>(
      BigInt.zero,
      (total, token) => total + token.amount,
    );
    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    if (swappedPoolTotal <= BigInt.zero && regularToken == null) {
      return Result.failure(
        'No local eCash token is available. Receive a token into the app before buying TollGate access offline.',
      );
    }

    if (swappedPoolTotal < BigInt.from(amountSats) &&
        regularToken?.amount != BigInt.from(amountSats)) {
      return Result.failure(
        'You need $amountSats sats, but only $swappedPoolTotal sats are available in swapped eCash and the regular token does not match exactly.',
      );
    }

    Token? lastToken;
    String? lastAuthToken;
    try {
      if (swappedPoolTotal >= BigInt.from(amountSats)) {
        final remainingTokens = [...swappedOneSatTokens];
        for (var i = 0; i < amountSats; i++) {
          final token = remainingTokens.removeAt(0);
          if (token.amount != BigInt.one) {
            return Result.failure(
              'Swapped eCash contains a non-1-sat token. Swap again before topping up TollGate.',
            );
          }
          lastToken = token;

          final paymentResult =
              await ref.read(tollgateServiceProvider).submitEcashToken(
                    cashuToken: token.encoded,
                    authToken: lastAuthToken ?? authToken,
                  );

          switch (paymentResult) {
            case Ok(value: final paymentResponse):
              lastAuthToken = paymentResponse.authToken ?? lastAuthToken;
              await ref.read(storeSwappedOneSatTokensProvider(
                remainingTokens.map((token) => token.encoded).toList(),
              ).future);
            case Failure(failure: final failure):
              return Result.failure(failure.message);
          }
        }
      } else if (regularToken!.amount == BigInt.from(amountSats)) {
        lastToken = regularToken;
        final paymentResult =
            await ref.read(tollgateServiceProvider).submitEcashToken(
                  cashuToken: regularToken.encoded,
                  authToken: authToken,
                );
        switch (paymentResult) {
          case Ok(value: final paymentResponse):
            lastAuthToken = paymentResponse.authToken;
          case Failure(failure: final failure):
            return Result.failure(failure.message);
        }
      } else {
        return Result.failure(
          'The regular local eCash token cannot be split exactly into $amountSats sats offline. Swap all local eCash into swapped eCash first from the wallet page.',
        );
      }
    } catch (error) {
      return Result.failure(
          'Failed to prepare the TollGate payment token. $error');
    }

    if (regularToken != null &&
        swappedPoolTotal < BigInt.from(amountSats) &&
        regularToken.amount == BigInt.from(amountSats)) {
      await ref.read(clearLocalEcashProvider.future);
    }

    final completedToken = lastToken;
    if (completedToken == null) {
      return Result.failure('No TollGate payment token was sent.');
    }

    await ref.read(tollgatePaymentHistoryStorageProvider).add(
          TollgatePaymentHistoryEntry(
            id: '${DateTime.now().millisecondsSinceEpoch}-$amountSats',
            amountSats: amountSats,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            status: lastAuthToken == null ? 'accepted' : 'accepted',
            ssid: ssid,
            dataLabel: dataLabel,
          ),
        );
    ref.invalidate(walletHistoryProvider);

    return Result.ok(
      TollgateTopUpResult(
        token: completedToken,
        paymentResponse: TollGatePaymentResponse(
          status: 'accepted',
          authToken: lastAuthToken,
        ),
        amountSats: amountSats,
      ),
    );
  }
}
