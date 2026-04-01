import 'dart:async';

import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/presentation/features/wallet/providers/current_mint_provider.dart';
import 'package:tollgate_app/presentation/features/wallet/providers/local_ecash_providers.dart';

import '../../../../../core/result/result.dart';
import '../../../../../core/result/unit.dart';
import '../../../../../domain/wallet/errors/wallet_errors.dart';
import '../../../../../domain/wallet/value_objects/send_amount.dart';
import '../../providers/mint_transactions_providers.dart';
import '../../providers/wallet_transactions_provider.dart';

part 'reserve_screen_notifier.freezed.dart';
part 'reserve_screen_notifier.g.dart';

/// State for the reserve screen
@freezed
sealed class ReserveScreenState with _$ReserveScreenState {
  /// State for entering the amount
  const factory ReserveScreenState.editing({
    required Mint mint,
    required SendAmount amount,
    required bool isPreparingSend,
    required bool showErrorMessages,
    PrepareSendFailure? error,
  }) = ReserveScreenEditingState;

  /// State for confirming the amount and fee
  const factory ReserveScreenState.confirming({
    required Mint mint,
    required PreparedSend preparedSend,
    required bool isGeneratingToken,
    SendFailure? error,
  }) = ReserveScreenConfirmingState;

  /// State for displaying the generated token
  const factory ReserveScreenState.complete({
    required Token token,
  }) = ReserveScreenCompleteState;
}

/// Notifier for the reserve screen
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
      amount: SendAmount.fromData(BigInt.from(0)),
      isPreparingSend: false,
      showErrorMessages: false,
    );
  }

  /// Updates the amount to reserve
  void updateAmount(String amountString) {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenEditingState) {
      return;
    }

    // Try to parse the amount
    BigInt? newAmount;
    try {
      final amount = double.parse(amountString);
      // Convert to sats
      newAmount = BigInt.from(amount);
    } catch (e) {
      // Ignore parsing errors here
    }

    update((state) => (state as ReserveScreenEditingState).copyWith(
          amount: SendAmount.fromData(newAmount ?? BigInt.from(0)),
        ));
  }

  /// Validates the amount
  Result<Unit, PrepareSendFailure> validateAmount() {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenEditingState) {
      return Result.failure(
        PrepareSendFailure.unexpected('Invalid state'),
      );
    }

    final amount = currentState.amount;
    if (amount.value <= BigInt.from(0)) {
      return Result.failure(
        PrepareSendFailure.unexpected('Amount must be greater than 0'),
      );
    }

    return Result.ok(unit);
  }

  /// Prepares to reserve eCash by creating a send transaction
  Future<void> prepareReserve() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenEditingState) {
      return;
    }

    // Validate the amount
    final validationResult = validateAmount();

    if (validationResult.isFailure) {
      update((state) => (state as ReserveScreenEditingState).copyWith(
            showErrorMessages: true,
          ));
      return;
    }

    update((state) => (state as ReserveScreenEditingState).copyWith(
          isPreparingSend: true,
        ));

    final prepareSendResult = await ref.read(
        prepareSendProvider(currentState.mint, currentState.amount).future);

    switch (prepareSendResult) {
      case Ok(value: final preparedSend):
        update((state) => ReserveScreenState.confirming(
              mint: currentState.mint,
              preparedSend: preparedSend,
              isGeneratingToken: false,
            ));
        return;
      case Failure(failure: final failure):
        // Show errors if validation fails
        update((state) => (state as ReserveScreenEditingState).copyWith(
              showErrorMessages: true,
              error: failure,
            ));
        return;
    }
  }

  /// Generates the token and stores it locally
  Future<void> generateAndStoreToken() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! ReserveScreenConfirmingState) {
      return;
    }

    update((state) => (state as ReserveScreenConfirmingState).copyWith(
          isGeneratingToken: true,
        ));

    final generateTokenResult = await ref.read(
        sendProvider(currentState.preparedSend, currentState.mint).future);

    switch (generateTokenResult) {
      case Ok(value: final token):
        // Store the token locally
        await ref.read(storeLocalEcashProvider(token.encoded).future);
        ref.invalidate(walletTransactionsProvider);

        // Update state to show success
        update((state) => ReserveScreenState.complete(
              token: token,
            ));
        return;
      case Failure(failure: final failure):
        update((state) => (state as ReserveScreenConfirmingState).copyWith(
              isGeneratingToken: false,
              error: failure,
            ));
        return;
    }
  }
}
