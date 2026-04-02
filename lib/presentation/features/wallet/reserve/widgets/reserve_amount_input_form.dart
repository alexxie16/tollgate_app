import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';

import '../controllers/reserve_screen_notifier.dart';

class ReserveAmountInputForm extends HookConsumerWidget {
  final ReserveScreenEditingState state;
  final ReserveScreenNotifier reserveScreenNotifier;

  const ReserveAmountInputForm({
    super.key,
    required this.state,
    required this.reserveScreenNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountFocusNode = useFocusNode();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final showError = state.showErrorMessages;

    return Card(
      elevation: 0,
      color: isDarkMode
          ? context.colorScheme.primary.withAlpha(25)
          : context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.colorScheme.outline.withAlpha(178),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          autovalidateMode: state.showErrorMessages
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reserve eCash',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Specify how much eCash you want to reissue and store offline for TollGate. The app will ask the mint for many 1 sat proofs during reserve.',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? context.colorScheme.surface
                      : context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.offline_bolt_rounded,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        focusNode: amountFocusNode,
                        initialValue: state.amount.value.toString() == '0'
                            ? ''
                            : state.amount.value.toString(),
                        onChanged: (value) {
                          reserveScreenNotifier.updateAmount(value);
                        },
                        validator: (_) {
                          return showError && state.amount.value <= BigInt.zero
                              ? 'Please enter a valid amount'
                              : null;
                        },
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : null,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode
                              ? context.colorScheme.surface
                              : context.colorScheme.surfaceContainerHighest,
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: context.textTheme.headlineSmall?.copyWith(
                            color: context.colorScheme.onSurface.withAlpha(100),
                            fontWeight: FontWeight.bold,
                          ),
                          suffixText: 'sats',
                          suffixStyle: context.textTheme.titleMedium?.copyWith(
                            color: context.colorScheme.onSurface.withAlpha(100),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.error.toString(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isPreparingReserve
                      ? null
                      : () {
                          reserveScreenNotifier.prepareReserve();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isPreparingReserve
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Reserve',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
