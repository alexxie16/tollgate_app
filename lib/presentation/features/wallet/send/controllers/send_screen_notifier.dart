import 'dart:async';

import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

    final swappedToken =
        await ref.read(swappedEcashLocalTokenStreamProvider.future);
    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    final localToken = swappedToken ?? regularToken;
    if (localToken == null) {
      update(
        (_) => currentState.copyWith(
          isPreparingSend: false,
          error: 'No local eCash token stored. Receive a token first.',
        ),
      );
      return;
    }

    if (localToken.amount < currentState.amount.value) {
      update(
        (_) => currentState.copyWith(
          isPreparingSend: false,
          error:
              'The stored local token only has ${localToken.amount} sats, but this send needs ${currentState.amount.value} sats.',
        ),
      );
      return;
    }

    try {
      splitTokenExact(token: localToken, amount: currentState.amount.value);
    } catch (_) {
      update(
        (_) => currentState.copyWith(
          isPreparingSend: false,
          error:
              'The active local token cannot be split exactly into ${currentState.amount.value} sats. Swap your regular eCash into swapped eCash first or receive a more granular token.',
        ),
      );
      return;
    }

    update(
      (_) => SendScreenState.confirming(
        amount: currentState.amount,
        isGeneratingToken: false,
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

    final swappedToken =
        await ref.read(swappedEcashLocalTokenStreamProvider.future);
    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    final localToken = swappedToken ?? regularToken;
    if (localToken == null) {
      update(
        (_) => currentState.copyWith(
          isGeneratingToken: false,
          error: 'No local eCash token stored. Receive a token first.',
        ),
      );
      return;
    }

    late final SplitTokenResult splitResult;
    try {
      splitResult = splitTokenExact(
        token: localToken,
        amount: currentState.amount.value,
      );
    } catch (_) {
      update(
        (_) => currentState.copyWith(
          isGeneratingToken: false,
          error:
              'The active local token cannot be split exactly into ${currentState.amount.value} sats. Swap your regular eCash into swapped eCash first.',
        ),
      );
      return;
    }

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

    update(
      (_) => SendScreenState.tokenGenerated(
        token: splitResult.selected,
      ),
    );
  }
}
