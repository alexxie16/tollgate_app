import 'package:flutter/material.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/widgets/buttons/app_button.dart';

import '../controllers/send_screen_notifier.dart';

class SendConfirmationDisplay extends StatelessWidget {
  final SendScreenConfirmingState state;
  final SendScreenNotifier sendScreenNotifier;

  const SendConfirmationDisplay({
    super.key,
    required this.state,
    required this.sendScreenNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: context.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.colorScheme.outline.withAlpha(178),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Send',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
                context, 'Amount:', '${state.amount.value.toString()} sats'),
            const SizedBox(height: 12),
            Text(
              'The app will split the stored local eCash token offline and keep the remainder locally.',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Generate Token',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                sendScreenNotifier.generateToken();
              },
              isLoading: state.isGeneratingToken,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.destructive,
              onPressed: () {
                sendScreenNotifier.backToEditing();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final textStyle = context.textTheme.bodyLarge;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: textStyle),
      ],
    );
  }
}
