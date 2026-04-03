import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/providers/connectivity_stream_provider.dart';

import '../../../../config/providers/service_providers.dart';
import '../../../../data/services/wallet/local_ecash_wallet_service.dart';
import '../../../common/widgets/cards/loading_card.dart';
import '../../../common/widgets/snackbar/app_snackbar.dart';
import '../providers/local_ecash_providers.dart';

class BalanceCard extends ConsumerStatefulWidget {
  const BalanceCard({super.key});

  @override
  ConsumerState<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<BalanceCard> {
  bool _isSwapping = false;
  String? _statusMessage;

  Future<void> _swapAllLocalEcash({
    required Token? regularToken,
    required Token? legacySwappedToken,
    required List<LocalEcashPendingBalance> stagingBalances,
  }) async {
    final hasInternet =
        ref.read(connectivityStreamProvider).valueOrNull ?? false;
    if (!hasInternet) {
      AppSnackBar.showError(
        context,
        message: 'Internet is required to swap local eCash into 1 sat proofs.',
      );
      return;
    }

    if (regularToken == null &&
        legacySwappedToken == null &&
        stagingBalances.isEmpty) {
      AppSnackBar.showInfo(context,
          message: 'No local eCash is available to swap.');
      return;
    }

    setState(() {
      _isSwapping = true;
      _statusMessage = null;
    });

    try {
      await ref.read(localEcashWalletServiceProvider).swapAllToOneSatPool(
            regularToken: regularToken,
            legacySwappedToken: legacySwappedToken,
          );
      if (regularToken != null) {
        await ref.read(clearLocalEcashProvider.future);
      }
      if (legacySwappedToken != null) {
        await ref.read(clearLegacySwappedEcashProvider.future);
      }
      ref.invalidate(stagingEcashPendingBalancesProvider);
      ref.invalidate(swappedEcashPoolBalancesProvider);
      ref.invalidate(swappedEcashBalanceProvider);

      if (!mounted) {
        return;
      }
      setState(() {
        _isSwapping = false;
        _statusMessage = 'Local eCash was swapped into the one-sat pool.';
      });
      AppSnackBar.showSuccess(
        context,
        message: 'Local eCash was swapped into the one-sat pool.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSwapping = false;
        _statusMessage = 'Swap failed: $error';
      });
      AppSnackBar.showError(context, message: 'Swap failed.\n$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final regularTokenAsync = ref.watch(regularEcashLocalTokenStreamProvider);
    final legacySwappedTokenAsync =
        ref.watch(legacySwappedEcashLocalTokenStreamProvider);
    final swappedBalanceAsync = ref.watch(swappedEcashBalanceProvider);
    final stagingBalancesAsync = ref.watch(stagingEcashPendingBalancesProvider);
    final poolBalancesAsync = ref.watch(swappedEcashPoolBalancesProvider);
    final hasInternet =
        ref.watch(connectivityStreamProvider).valueOrNull ?? false;

    if (regularTokenAsync.isLoading ||
        legacySwappedTokenAsync.isLoading ||
        swappedBalanceAsync.isLoading ||
        stagingBalancesAsync.isLoading ||
        poolBalancesAsync.isLoading) {
      return const LoadingCard();
    }

    final regularToken = regularTokenAsync.valueOrNull;
    final legacySwappedToken = legacySwappedTokenAsync.valueOrNull;
    final swappedBalance = swappedBalanceAsync.valueOrNull ?? BigInt.zero;
    final stagingBalances =
        stagingBalancesAsync.valueOrNull ?? const <LocalEcashPendingBalance>[];
    final poolBalances =
        poolBalancesAsync.valueOrNull ?? const <LocalEcashPendingBalance>[];

    return _buildWidget(
      context,
      regularToken: regularToken,
      legacySwappedToken: legacySwappedToken,
      swappedBalance: swappedBalance,
      stagingBalances: stagingBalances,
      poolBalances: poolBalances,
      hasInternet: hasInternet,
      statusMessage: _statusMessage,
    );
  }

  Widget _buildWidget(
    BuildContext context, {
    required Token? regularToken,
    required Token? legacySwappedToken,
    required BigInt swappedBalance,
    required List<LocalEcashPendingBalance> stagingBalances,
    required List<LocalEcashPendingBalance> poolBalances,
    required bool hasInternet,
    required String? statusMessage,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fadedTextColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local eCash',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          _buildBalanceItem(
            context,
            'Regular eCash',
            regularToken?.amount ?? BigInt.zero,
            regularToken?.mintUrl,
            fadedTextColor,
            textColor,
          ),
          const SizedBox(height: 16),
          _buildBalanceItem(
            context,
            'Swapped eCash',
            swappedBalance,
            null,
            fadedTextColor,
            textColor,
          ),
          if (legacySwappedToken != null) ...[
            const SizedBox(height: 16),
            Text(
              'Legacy swapped token waiting to be imported',
              style: context.textTheme.bodySmall?.copyWith(
                color: fadedTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${legacySwappedToken.amount} sats from ${legacySwappedToken.mintUrl}',
              style: context.textTheme.bodySmall,
            ),
          ],
          if (poolBalances.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Swapped eCash pools',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...poolBalances.map(
              (pending) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${pending.amount} sats at ${pending.mintUrl}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: fadedTextColor,
                  ),
                ),
              ),
            ),
          ],
          if (stagingBalances.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Pending staging balances',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...stagingBalances.map(
              (pending) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${pending.amount} sats at ${pending.mintUrl}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: fadedTextColor,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSwapping || !hasInternet
                  ? null
                  : () => _swapAllLocalEcash(
                        regularToken: regularToken,
                        legacySwappedToken: legacySwappedToken,
                        stagingBalances: stagingBalances,
                      ),
              icon: _isSwapping
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.swap_horiz_rounded),
              label: Text(
                hasInternet ? 'Swap All Local eCash' : 'Swap Needs Internet',
              ),
            ),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              statusMessage,
              style: context.textTheme.bodySmall?.copyWith(
                color: fadedTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
    BuildContext context,
    String label,
    BigInt balance,
    String? mintUrl,
    Color fadedTextColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: fadedTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              balance.toString(),
              style: context.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'sats',
              style: context.textTheme.bodyMedium?.copyWith(
                color: fadedTextColor,
              ),
            ),
          ],
        ),
        if (mintUrl != null) ...[
          const SizedBox(height: 4),
          Text(
            mintUrl,
            style: context.textTheme.bodySmall?.copyWith(
              color: fadedTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
