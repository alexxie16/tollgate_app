import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../common/widgets/cards/loading_card.dart';
import '../../../router/routes.dart';
import '../../wallet/providers/local_ecash_providers.dart';

class WalletCard extends ConsumerWidget {
  const WalletCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regularTokenAsync = ref.watch(regularEcashLocalTokenStreamProvider);
    final swappedBalanceAsync = ref.watch(swappedEcashBalanceProvider);

    if (regularTokenAsync.isLoading || swappedBalanceAsync.isLoading) {
      return const LoadingCard();
    }

    final regularBalance = regularTokenAsync.valueOrNull?.amount ?? BigInt.zero;
    final swappedBalance = swappedBalanceAsync.valueOrNull ?? BigInt.zero;
    final totalBalance = regularBalance + swappedBalance;
    final status = regularTokenAsync.hasError || swappedBalanceAsync.hasError
        ? 'Some local eCash could not be loaded. Tap to manage wallet.'
        : 'Tap to manage wallet';

    return _buildWidget(
      context,
      balance: totalBalance,
      footerText: status,
    );
  }

  InkWell _buildWidget(BuildContext context,
      {required BigInt balance, required String footerText}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push(Routes.wallet),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wallet',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? colorScheme.primary.withAlpha(25)
                  : Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local eCash',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$balance',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'sats',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              footerText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
