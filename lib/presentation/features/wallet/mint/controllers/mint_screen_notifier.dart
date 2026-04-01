import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/presentation/features/wallet/providers/current_mint_provider.dart';

import '../../../../../core/result/result.dart';
import '../../../../../core/result/unit.dart';
import '../../../../../domain/wallet/value_objects/mint_amount.dart';

part 'mint_screen_notifier.freezed.dart';
part 'mint_screen_notifier.g.dart';

/// Notifier for the mint screen
@riverpod
class MintScreenNotifier extends _$MintScreenNotifier {
  @override
  FutureOr<MintScreenState> build() async {
    final currentMint = await ref.watch(currentMintProvider.future);
    if (currentMint == null) {
      throw Exception('A mint should be selected at this point');
    }
    return MintScreenState.editing(
      mint: currentMint,
      amount: BigInt.zero,
      isGeneratingInvoice: false,
      showErrorMessages: false,
    );
  }

  void amountChanged(String amountStr) {
    if (amountStr.isEmpty) {
      update((state) =>
          (state as MintScreenEditingState).copyWith(amount: BigInt.zero));
      return;
    }
    final amount = BigInt.tryParse(amountStr.trim());
    if (amount == null) {
      throw Exception('Invalid amount format.');
    }
    update(
        (state) => (state as MintScreenEditingState).copyWith(amount: amount));
  }

  Result<Unit, MintAmountValidationFailure> validateAmount() {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! MintScreenEditingState) {
      throw Exception('Current state is not an MintScreenEditingState');
    }
    return MintAmount.validate(currentState.amount);
  }

  /// Generates a Lightning invoice for the specified amount
  Future<void> generateInvoice() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null) return;

    if (currentState is! MintScreenEditingState) {
      throw Exception('Current state is not an MintScreenEditingState');
    }

    final mintAmountResult = MintAmount.create(currentState.amount);
    if (mintAmountResult.isFailure) {
      update((state) => (state as MintScreenEditingState).copyWith(
            showErrorMessages: true,
            isGeneratingInvoice: false,
          ));
      return;
    }

    update((state) => (state as MintScreenEditingState).copyWith(
          isGeneratingInvoice: true,
        ));

    // Create a MintAmount value object from the current amount
    switch (mintAmountResult) {
      case Ok(value: final mintAmount):
        update((state) => MintScreenState.invoice(
              mint: state.mint,
              mintAmount: mintAmount,
            ));
        return;
      case Failure():
        return;
    }
  }

  void clearErrors() {
    update((state) => (state as MintScreenEditingState).copyWith(
          showErrorMessages: false,
        ));
  }

  /// Resets the state to the initial state
  void reset() {
    update((state) => MintScreenState.editing(
          mint: state.mint,
          amount: BigInt.zero,
          isGeneratingInvoice: false,
          showErrorMessages: false,
        ));
  }
}

/// State for the mint screen
@freezed
sealed class MintScreenState with _$MintScreenState {
  factory MintScreenState.editing({
    required Mint mint,
    required BigInt amount,
    required bool isGeneratingInvoice,
    required bool showErrorMessages,
  }) = MintScreenEditingState;

  factory MintScreenState.invoice({
    required Mint mint,
    required MintAmount mintAmount,
  }) = MintScreenInvoiceState;
}
