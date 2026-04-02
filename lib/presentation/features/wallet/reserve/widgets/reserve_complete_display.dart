import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/widgets/buttons/app_button.dart';

class ReserveCompleteDisplay extends StatelessWidget {
  final Token token;
  final VoidCallback onClose;

  const ReserveCompleteDisplay({
    super.key,
    required this.token,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Reserve Successful!',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '${token.amount.toString()} sats have been reserved as local eCash for use with TollGate. When possible, the token now uses many 1 sat proofs for easier offline top-ups.',
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Done',
                  onPressed: onClose,
                  variant: AppButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
