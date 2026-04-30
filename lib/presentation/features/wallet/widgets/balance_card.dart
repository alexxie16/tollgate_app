import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/providers/connectivity_stream_provider.dart';

import '../../../../config/providers/service_providers.dart';
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

  Future<void> _swapAllLocalEcash() async {
    final hasInternet =
        ref.read(connectivityStreamProvider).valueOrNull ?? false;
    if (!hasInternet) {
      AppSnackBar.showError(
        context,
        message: 'Internet is required to swap local eCash into 1 sat proofs.',
      );
      return;
    }

    final regularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    final stagingBalances =
        await ref.read(stagingEcashPendingBalancesProvider.future);

    if (!mounted) {
      return;
    }

    if (regularToken == null && stagingBalances.isEmpty) {
      AppSnackBar.showInfo(context,
          message: 'No regular eCash is available to swap.');
      return;
    }

    setState(() {
      _isSwapping = true;
      _statusMessage = null;
    });

    try {
      await ref.read(localEcashWalletServiceProvider).swapAllToOneSatPool(
            regularToken: regularToken,
          );
      if (regularToken != null) {
        await ref.read(clearLocalEcashProvider.future);
      }
      ref.invalidate(stagingEcashPendingBalancesProvider);
      ref.invalidate(swappedEcashPoolBalancesProvider);
      ref.invalidate(swappedEcashBalanceProvider);
      final refreshedRegularBalance =
          await ref.refresh(regularEcashBalanceProvider.future);
      final refreshedSwappedBalance =
          await ref.refresh(swappedEcashBalanceProvider.future);
      assert(refreshedRegularBalance >= BigInt.zero);
      assert(refreshedSwappedBalance >= BigInt.zero);

      if (!mounted) {
        return;
      }
      setState(() {
        _isSwapping = false;
        _statusMessage = 'Regular eCash was swapped into swapped eCash.';
      });
      AppSnackBar.showSuccess(
        context,
        message: 'Regular eCash was swapped into swapped eCash.',
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
    final regularBalanceAsync = ref.watch(regularEcashBalanceProvider);
    final swappedBalanceAsync = ref.watch(swappedEcashBalanceProvider);
    final hasInternet =
        ref.watch(connectivityStreamProvider).valueOrNull ?? false;

    if (regularBalanceAsync.isLoading || swappedBalanceAsync.isLoading) {
      return const LoadingCard();
    }

    final regularBalance = regularBalanceAsync.valueOrNull ?? BigInt.zero;
    final swappedBalance = swappedBalanceAsync.valueOrNull ?? BigInt.zero;

    return _buildWidget(
      context,
      regularBalance: regularBalance,
      swappedBalance: swappedBalance,
      hasInternet: hasInternet,
      statusMessage: _statusMessage,
    );
  }

  Widget _buildWidget(
    BuildContext context, {
    required BigInt regularBalance,
    required BigInt swappedBalance,
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
            regularBalance,
            fadedTextColor,
            textColor,
          ),
          const SizedBox(height: 16),
          _buildBalanceItem(
            context,
            'Swapped eCash',
            swappedBalance,
            fadedTextColor,
            textColor,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _isSwapping || !hasInternet ? null : _swapAllLocalEcash,
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
                hasInternet ? 'Swap All Regular eCash' : 'Swap Needs Internet',
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
      ],
    );
  }
}
