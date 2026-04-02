import 'dart:async';

import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/presentation/features/wallet/providers/current_mint_provider.dart';
import 'package:tollgate_app/presentation/features/wallet/providers/local_ecash_providers.dart';

import '../../../../../config/providers/repository_providers.dart';
import '../../../../../config/providers/service_providers.dart';
import '../../../../../core/result/result.dart';
import '../../../../../core/result/unit.dart';
import '../../../../../domain/wallet/errors/wallet_errors.dart';
import '../../../../../domain/wallet/value_objects/send_amount.dart';
import '../../providers/wallet_balance_stream_provider.dart';
import '../../providers/wallet_transactions_provider.dart';

part 'reserve_screen_notifier.freezed.dart';
part 'reserve_screen_notifier.g.dart';

@freezed
sealed class ReserveScreenState with _$ReserveScreenState {
  const factory ReserveScreenState.editing({
    required Mint mint,
    required SendAmount amount,
    required bool isPreparingReserve,
    required bool showErrorMessages,
    String? error,
  }) = ReserveScreenEditingState;

  const factory ReserveScreenState.confirming({
    required Mint mint,
    required SendAmount amount,
    required bool isGeneratingToken,
    String? error,
  }) = ReserveScreenConfirmingState;

  const factory ReserveScreenState.complete({
    required Token token,
  }) = ReserveScreenCompleteState;
}

@riverpod
class ReserveScreenNotifier extends _$ReserveScreenNotifier {
  @override
  FutureOr<ReserveScreenState> build() async {
    final currentMint = await ref.watch(currentMintProvider.future);
    if (currentMint == null) {
      throw Exception('A mint should be selected at this point');
    }

    return ReserveScreenState.editing(
      mint: currentMint,
      amount: SendAmount.fromData(BigInt.zero),
      isPreparingReserve: false,
      showErrorMessages: false,
    );
  }

  void updateAmount(String amountString) {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenEditingState) {
      return;
    }

    BigInt? newAmount;
    try {
      final amount = double.parse(amountString);
      newAmount = BigInt.from(amount);
    } catch (_) {}

    update(
      (state) => (state as ReserveScreenEditingState).copyWith(
        amount: SendAmount.fromData(newAmount ?? BigInt.zero),
        error: null,
      ),
    );
  }

  Result<Unit, PrepareSendFailure> validateAmount() {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenEditingState) {
      return Result.failure(
        PrepareSendFailure.unexpected('Invalid state'),
      );
    }

    final amount = currentState.amount;
    if (amount.value <= BigInt.zero) {
      return Result.failure(
        PrepareSendFailure.unexpected('Amount must be greater than 0'),
      );
    }

    return Result.ok(unit);
  }

  Future<void> prepareReserve() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenEditingState) {
      return;
    }

    final validationResult = validateAmount();
    if (validationResult.isFailure) {
      update(
        (state) => (state as ReserveScreenEditingState).copyWith(
          showErrorMessages: true,
        ),
      );
      return;
    }

    update(
      (_) => ReserveScreenState.confirming(
        mint: currentState.mint,
        amount: currentState.amount,
        isGeneratingToken: false,
      ),
    );
  }

  Future<void> generateAndStoreToken() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenConfirmingState) {
      return;
    }

    update(
      (state) => (state as ReserveScreenConfirmingState).copyWith(
        isGeneratingToken: true,
        error: null,
      ),
    );

    final existingLocalToken =
        await ref.read(ecashLocalTokenStreamProvider.future);
    if (existingLocalToken != null) {
      update(
        (state) => (state as ReserveScreenConfirmingState).copyWith(
          isGeneratingToken: false,
          error:
              'A local eCash token is already stored. Use it first before reserving a new one.',
        ),
      );
      return;
    }

    final reserveWalletService = ref.read(reserveWalletServiceProvider);
    final pendingReserveBalance =
        await reserveWalletService.reserveBalance(currentState.mint.url);
    if (pendingReserveBalance > BigInt.zero) {
      final recoveredToken = await reserveWalletService.exportReservedToken(
        mintUrl: currentState.mint.url,
        amount: pendingReserveBalance,
      );
      await _storeReservedToken(recoveredToken);
      return;
    }

    final walletRepo = await ref.read(walletRepositoryProvider.future);
    final prepareSendResult = await walletRepo.prepareSend(
      mint: currentState.mint,
      amount: currentState.amount,
    );

    late final PreparedSend preparedSend;
    switch (prepareSendResult) {
      case Ok(value: final value):
        preparedSend = value;
      case Failure(failure: final failure):
        update(
          (state) => (state as ReserveScreenConfirmingState).copyWith(
            isGeneratingToken: false,
            error: failure.toString(),
          ),
        );
        return;
    }

    final sendResult = await walletRepo.send(
      mint: currentState.mint,
      preparedSend: preparedSend,
    );

    late final Token temporaryToken;
    switch (sendResult) {
      case Ok(value: final value):
        temporaryToken = value;
      case Failure(failure: final failure):
        update(
          (state) => (state as ReserveScreenConfirmingState).copyWith(
            isGeneratingToken: false,
            error: failure.toString(),
          ),
        );
        return;
    }

    ref.invalidate(walletBalanceStreamProvider);
    ref.invalidate(walletTransactionsProvider);

    try {
      await reserveWalletService.importTokenAsOneSatProofs(
        mintUrl: currentState.mint.url,
        token: temporaryToken,
      );
    } catch (_) {
      await _storeReservedToken(temporaryToken);
      return;
    }

    try {
      final finalToken = await reserveWalletService.exportReservedToken(
        mintUrl: currentState.mint.url,
        amount: currentState.amount.value,
      );
      await _storeReservedToken(finalToken);
    } catch (_) {
      update(
        (state) => (state as ReserveScreenConfirmingState).copyWith(
          isGeneratingToken: false,
          error:
              'The reserve token has been reissued into small proofs, but exporting it failed. Retry reserve to recover the pending balance.',
        ),
      );
    }
  }

  Future<void> _storeReservedToken(Token token) async {
    await ref.read(storeLocalEcashProvider(token.encoded).future);
    update(
      (_) => ReserveScreenState.complete(token: token),
    );
  }
}
