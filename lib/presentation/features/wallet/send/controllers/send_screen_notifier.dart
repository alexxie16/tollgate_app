import 'dart:async';

import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/presentation/features/wallet/providers/current_mint_provider.dart';

import '../../../../../core/result/result.dart';
import '../../../../../core/result/unit.dart';
import '../../../../../domain/wallet/errors/wallet_errors.dart';
import '../../../../../domain/wallet/value_objects/send_amount.dart';
import '../../providers/mint_transactions_providers.dart';
import '../../providers/wallet_transactions_provider.dart';

part 'send_screen_notifier.freezed.dart';
part 'send_screen_notifier.g.dart';

/// State for the send screen
@freezed
sealed class SendScreenState with _$SendScreenState {
  /// State for entering the amount
  const factory SendScreenState.editing({
    required Mint mint,
    required SendAmount amount,
    required bool isPreparingSend,
    required bool showErrorMessages,
    PrepareSendFailure? error,
  }) = SendScreenEditingState;

  /// State for confirming the amount and fee
  const factory SendScreenState.confirming({
    required Mint mint,
    required PreparedSend preparedSend,
    required bool isGeneratingToken,
    SendFailure? error,
  }) = SendScreenConfirmingState;

  /// State for displaying the generated token
  const factory SendScreenState.tokenGenerated({
    required Token token,
  }) = SendScreenTokenState;
}

/// Notifier for the send screen
@riverpod
class SendScreenNotifier extends _$SendScreenNotifier {
  @override
  FutureOr<SendScreenState> build() async {
    final currentMint = await ref.watch(currentMintProvider.future);
    if (currentMint == null) {
      throw Exception('A mint should be selected at this point');
    }
    return SendScreenState.editing(
      mint: currentMint,
      amount: SendAmount.fromData(BigInt.zero),
      isPreparingSend: false,
      showErrorMessages: false,
    );
  }

  void amountChanged(String amountStr) {
    if (amountStr.isEmpty) {
      update((state) => (state as SendScreenEditingState)
          .copyWith(amount: SendAmount.fromData(BigInt.zero)));
      return;
    }
    final amount = BigInt.tryParse(amountStr.trim());
    if (amount == null) {
      // Keep the current state if parsing fails
      return;
    }
    update((state) => (state as SendScreenEditingState)
        .copyWith(amount: SendAmount.fromData(amount)));
  }

  Result<Unit, SendAmountValidationFailure> validateAmount() {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenEditingState) {
      throw Exception('Invalid state');
    }
    return SendAmount.validate(currentState.amount.value);
  }

  /// Proceeds to the confirmation step after preparing the send
  Future<void> prepareSend() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenEditingState) return;

    // Validate the amount
    final validationResult = validateAmount();

    if (validationResult.isFailure) {
      update((state) => (state as SendScreenEditingState).copyWith(
            showErrorMessages: true,
          ));
      return;
    }

    update((state) => (state as SendScreenEditingState).copyWith(
          isPreparingSend: true,
        ));

    final prepareSendResult = await ref.read(
        prepareSendProvider(currentState.mint, currentState.amount).future);

    switch (prepareSendResult) {
      case Ok(value: final preparedSend):
        update((state) => SendScreenState.confirming(
              mint: currentState.mint,
              preparedSend: preparedSend,
              isGeneratingToken: false,
            ));
        return;
      case Failure(failure: final failure):
        // Show errors if validation fails
        update((state) => (state as SendScreenEditingState).copyWith(
              showErrorMessages: true,
              error: failure,
            ));
        return;
    }
  }

  /// Generates the send token after confirmation
  Future<void> generateToken() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenConfirmingState) {
      return;
    }

    update((state) => (state as SendScreenConfirmingState).copyWith(
          isGeneratingToken: true,
        ));

    final generateTokenResult = await ref.read(
        sendProvider(currentState.preparedSend, currentState.mint).future);

    switch (generateTokenResult) {
      case Ok(value: final token):
        ref.invalidate(walletTransactionsProvider);
        update((state) => SendScreenState.tokenGenerated(
              token: token,
            ));
        return;
      case Failure(failure: final failure):
        update((state) => (state as SendScreenConfirmingState).copyWith(
              isGeneratingToken: false,
              error: failure,
            ));
        return;
    }
  }
}
