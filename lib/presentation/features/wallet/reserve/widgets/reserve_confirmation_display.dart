import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/widgets/buttons/app_button.dart';

import '../controllers/reserve_screen_notifier.dart';

class ReserveConfirmationDisplay extends StatelessWidget {
  final ReserveScreenConfirmingState state;
  final ReserveScreenNotifier reserveScreenNotifier;

  const ReserveConfirmationDisplay({
    super.key,
    required this.state,
    required this.reserveScreenNotifier,
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
              'Confirm Reserve',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
                context, 'Amount:', '${state.amount.value.toString()} sats'),
            const SizedBox(height: 8),
            Text(
              'The app will temporarily reissue this amount through the mint into many 1 sat proofs, then export the final local token for TollGate use.',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Reserve 1-sat Token',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                reserveScreenNotifier.generateAndStoreToken();
              },
              isLoading: state.isGeneratingToken,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.destructive,
              onPressed: () {
                context.pop(); // Go back to editing state
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
