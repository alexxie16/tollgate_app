import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/extensions/tollgate_info_x.dart';

import '../../../../domain/tollgate/models/tollgate_info.dart';
import '../../../common/widgets/buttons/app_button.dart';
import '../../../router/routes.dart';

class ConnectedTollgateCard extends ConsumerWidget {
  final String ssid;
  final TollGateInfo tollgateInfo;
  final bool hasInternet;
  final int remainingSeconds;

  const ConnectedTollgateCard({
    super.key,
    required this.ssid,
    required this.tollgateInfo,
    required this.hasInternet,
    this.remainingSeconds = 0,
  });

  String _formatRemainingTime() {
    if (remainingSeconds <= 0) {
      return 'No time remaining';
    }

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasActiveSession = remainingSeconds > 0;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final String ssidStr = ssid.replaceAll('"', '');

    return Card(
      color: isDarkMode
          ? context.colorScheme.primary.withAlpha(25)
          : const Color(0xFFFAFAFA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Network', ssidStr),
            _buildInfoRow(
              'Pricing',
              tollgateInfo.humanReadablePrice(),
            ),
            if (tollgateInfo.mintUrl.isNotEmpty)
              _buildInfoRow('Mint URL', tollgateInfo.mintUrl),
            if (hasActiveSession) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Remaining Time', _formatRemainingTime()),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: remainingSeconds / 300,
                  minHeight: 8,
                  backgroundColor: context.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colorScheme.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    variant: AppButtonVariant.secondary,
                    label: 'Top Up',
                    onPressed: () {
                      context.push('${Routes.home}payment', extra: {
                        'ssid': ssid,
                        'tollgateInfo': tollgateInfo,
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
