import 'dart:async';

import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../config/providers/service_providers.dart';
import '../../../../../core/result/result.dart';
import '../../../../../core/result/unit.dart';
import '../../../../../domain/wallet/value_objects/send_amount.dart';
import '../../providers/local_ecash_providers.dart';

part 'send_screen_notifier.freezed.dart';
part 'send_screen_notifier.g.dart';

@freezed
sealed class SendScreenState with _$SendScreenState {
  const factory SendScreenState.editing({
    required SendAmount amount,
    required bool isPreparingSend,
    required bool showErrorMessages,
    String? error,
  }) = SendScreenEditingState;

  const factory SendScreenState.confirming({
    required SendAmount amount,
    required bool isGeneratingToken,
    String? error,
  }) = SendScreenConfirmingState;

  const factory SendScreenState.tokenGenerated({
    required Token token,
  }) = SendScreenTokenState;
}

@riverpod
class SendScreenNotifier extends _$SendScreenNotifier {
  @override
  FutureOr<SendScreenState> build() {
    return SendScreenState.editing(
      amount: SendAmount.fromData(BigInt.zero),
      isPreparingSend: false,
      showErrorMessages: false,
    );
  }

  void amountChanged(String amountStr) {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenEditingState) {
      return;
    }

    if (amountStr.isEmpty) {
      update(
        (_) => currentState.copyWith(
          amount: SendAmount.fromData(BigInt.zero),
          error: null,
        ),
      );
      return;
    }

    final amount = BigInt.tryParse(amountStr.trim());
    if (amount == null) {
      return;
    }

    update(
      (_) => currentState.copyWith(
        amount: SendAmount.fromData(amount),
        error: null,
      ),
    );
  }

  Result<Unit, SendAmountValidationFailure> validateAmount() {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenEditingState) {
      throw Exception('Invalid state');
    }

    return SendAmount.validate(currentState.amount.value);
  }

  Future<void> prepareSend() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenEditingState) {
      return;
    }

    final validationResult = validateAmount();
    if (validationResult.isFailure) {
      update(
        (_) => currentState.copyWith(
          showErrorMessages: true,
        ),
      );
      return;
    }

    update(
      (_) => currentState.copyWith(
        isPreparingSend: true,
        error: null,
      ),
    );

    final BigInt swappedBalance =
        await ref.read(swappedEcashBalanceProvider.future);
    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    if (swappedBalance <= BigInt.zero && regularToken == null) {
      update(
        (_) => currentState.copyWith(
          isPreparingSend: false,
          error: 'No local eCash token stored. Receive a token first.',
        ),
      );
      return;
    }

    if (swappedBalance >= currentState.amount.value) {
      update(
        (_) => SendScreenState.confirming(
          amount: currentState.amount,
          isGeneratingToken: false,
        ),
      );
      return;
    }

    if (regularToken == null) {
      update(
        (_) => currentState.copyWith(
          isPreparingSend: false,
          error:
              'The swapped eCash pool is empty or too small, and no regular token is stored.',
        ),
      );
      return;
    }

    if (regularToken.amount == currentState.amount.value) {
      update(
        (_) => SendScreenState.confirming(
          amount: currentState.amount,
          isGeneratingToken: false,
        ),
      );
      return;
    }

    update(
      (_) => currentState.copyWith(
        isPreparingSend: false,
        error:
            'The regular token cannot be split exactly into ${currentState.amount.value} sats. Swap all local eCash into swapped eCash first.',
      ),
    );
  }

  void backToEditing() {
    final currentState = state.unwrapPrevious().valueOrNull;
    final amount = switch (currentState) {
      SendScreenEditingState(:final amount) => amount,
      SendScreenConfirmingState(:final amount) => amount,
      _ => SendAmount.fromData(BigInt.zero),
    };

    update(
      (_) => SendScreenState.editing(
        amount: amount,
        isPreparingSend: false,
        showErrorMessages: false,
      ),
    );
  }

  Future<void> generateToken() async {
    final currentState = state.unwrapPrevious().valueOrNull;
    if (currentState == null || currentState is! SendScreenConfirmingState) {
      return;
    }

    update(
      (_) => currentState.copyWith(
        isGeneratingToken: true,
        error: null,
      ),
    );

    final swappedPool = await ref
        .read(localEcashWalletServiceProvider)
        .poolWithAmount(currentState.amount.value);
    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    if (swappedPool == null && regularToken == null) {
      update(
        (_) => currentState.copyWith(
          isGeneratingToken: false,
          error: 'No local eCash token stored. Receive a token first.',
        ),
      );
      return;
    }

    try {
      if (swappedPool != null) {
        final token =
            await ref.read(localEcashWalletServiceProvider).exportToken(
                  mintUrl: swappedPool.mintUrl,
                  amount: currentState.amount.value,
                );
        ref.invalidate(swappedEcashPoolBalancesProvider);
        ref.invalidate(swappedEcashBalanceProvider);
        update(
          (_) => SendScreenState.tokenGenerated(token: token),
        );
        return;
      }

      if (regularToken != null &&
          regularToken.amount == currentState.amount.value) {
        await ref.read(clearLocalEcashProvider.future);
        update(
          (_) => SendScreenState.tokenGenerated(token: regularToken),
        );
        return;
      }

      update(
        (_) => currentState.copyWith(
          isGeneratingToken: false,
          error:
              'The regular token cannot be split exactly into ${currentState.amount.value} sats. Swap all local eCash into swapped eCash first.',
        ),
      );
    } catch (error) {
      update(
        (_) => currentState.copyWith(
          isGeneratingToken: false,
          error: 'Failed to create the token. $error',
        ),
      );
    }
  }
}
