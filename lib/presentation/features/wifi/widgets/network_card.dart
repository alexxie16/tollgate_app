import 'package:flutter/material.dart';

import '../../../../domain/wifi/models/wifi_network.dart';

class NetworkCard extends StatelessWidget {
  const NetworkCard({
    super.key,
    required this.network,
    this.onTap,
  });

  final WiFiNetwork network;
  final VoidCallback? onTap;

  Color _getSignalColor(double strength, ColorScheme colorScheme) {
    if (strength >= 0.75) return const Color(0xFF4CAF50); // Green
    if (strength >= 0.50) return const Color(0xFFFB8C00); // Orange
    return const Color(0xFFE57373); // Light Red
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pricingText = network.isTollGate
        ? network.satsPerMin != null
            ? '${network.satsPerMin} sats/min'
            : 'Pricing available after connect'
        : network.securityType;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Convert signal strength to percentage (typical range is -100 to 0)
    final signalPercent =
        ((network.signalStrength + 100) / 100).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode
              ? colorScheme.primary.withAlpha(25)
              : Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Network Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.wifi,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Network Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    network.ssid,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pricingText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Signal Strength
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  color: _getSignalColor(signalPercent, colorScheme),
                  size: 20,
                ),
                const SizedBox(height: 2),
                Text(
                  '${(signalPercent * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
