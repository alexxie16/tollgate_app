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

  Future<void> _swapAllRegularEcash({
    required Token regularToken,
    required Token? existingSwappedToken,
  }) async {
    final hasInternet =
        ref.read(connectivityStreamProvider).valueOrNull ?? false;
    if (!hasInternet) {
      AppSnackBar.showError(
        context,
        message:
            'Internet is required to swap regular eCash into 1 sat proofs.',
      );
      return;
    }

    setState(() {
      _isSwapping = true;
      _statusMessage = null;
    });

    try {
      final swappedToken = await ref
          .read(localEcashWalletServiceProvider)
          .swapTokenToOneSatProofs(
            regularToken: regularToken,
            existingSwappedToken: existingSwappedToken,
          );
      await ref.read(storeSwappedEcashProvider(swappedToken.encoded).future);
      await ref.read(clearLocalEcashProvider.future);

      if (!mounted) {
        return;
      }
      setState(() {
        _isSwapping = false;
        _statusMessage =
            'Swapped ${regularToken.amount} sats into swapped eCash with 1 sat proofs.';
      });
      AppSnackBar.showSuccess(
        context,
        message:
            'Swapped ${regularToken.amount} sats into swapped eCash with 1 sat proofs.',
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

  Future<void> _recoverPendingBalance(
    LocalEcashPendingBalance pending,
    Token? existingSwappedToken,
  ) async {
    setState(() {
      _isSwapping = true;
      _statusMessage = null;
    });

    try {
      final exportedPendingToken =
          await ref.read(localEcashWalletServiceProvider).exportToken(
                mintUrl: pending.mintUrl,
                amount: pending.amount,
              );

      if (existingSwappedToken != null) {
        final mergedToken = await ref
            .read(localEcashWalletServiceProvider)
            .swapTokenToOneSatProofs(
              regularToken: exportedPendingToken,
              existingSwappedToken: existingSwappedToken,
            );
        await ref.read(storeSwappedEcashProvider(mergedToken.encoded).future);
      } else {
        await ref.read(
            storeSwappedEcashProvider(exportedPendingToken.encoded).future);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isSwapping = false;
        _statusMessage = 'Recovered ${pending.amount} sats into swapped eCash.';
      });
      AppSnackBar.showSuccess(
        context,
        message: 'Recovered ${pending.amount} sats into swapped eCash.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSwapping = false;
        _statusMessage = 'Recovery failed: $error';
      });
      AppSnackBar.showError(context, message: 'Recovery failed.\n$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final regularTokenAsync = ref.watch(regularEcashLocalTokenStreamProvider);
    final swappedTokenAsync = ref.watch(swappedEcashLocalTokenStreamProvider);
    final pendingBalancesAsync = ref.watch(localEcashPendingBalancesProvider);
    final hasInternet =
        ref.watch(connectivityStreamProvider).valueOrNull ?? false;

    if (regularTokenAsync.isLoading ||
        swappedTokenAsync.isLoading ||
        pendingBalancesAsync.isLoading) {
      return const LoadingCard();
    }

    final regularToken = regularTokenAsync.valueOrNull;
    final swappedToken = swappedTokenAsync.valueOrNull;
    final pendingBalances =
        pendingBalancesAsync.valueOrNull ?? const <LocalEcashPendingBalance>[];

    return _buildWidget(
      context,
      regularToken: regularToken,
      swappedToken: swappedToken,
      pendingBalances: pendingBalances,
      hasInternet: hasInternet,
      statusMessage: _statusMessage,
    );
  }

  Widget _buildWidget(
    BuildContext context, {
    required Token? regularToken,
    required Token? swappedToken,
    required List<LocalEcashPendingBalance> pendingBalances,
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
            swappedToken?.amount ?? BigInt.zero,
            swappedToken?.mintUrl,
            fadedTextColor,
            textColor,
          ),
          if (regularToken != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSwapping || !hasInternet
                    ? null
                    : () => _swapAllRegularEcash(
                          regularToken: regularToken,
                          existingSwappedToken: swappedToken,
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
                  hasInternet
                      ? 'Swap All Regular eCash'
                      : 'Swap Needs Internet',
                ),
              ),
            ),
          ],
          if (pendingBalances.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Pending hidden-wallet balances',
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'These balances were found from earlier normalization or swap attempts and can be recovered into swapped eCash.',
              style: context.textTheme.bodySmall?.copyWith(
                color: fadedTextColor,
              ),
            ),
            const SizedBox(height: 12),
            ...pendingBalances.map(
              (pending) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pending.amount} sats',
                            style: context.textTheme.titleSmall,
                          ),
                          Text(
                            pending.mintUrl,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: fadedTextColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _isSwapping
                          ? null
                          : () => _recoverPendingBalance(pending, swappedToken),
                      child: const Text('Recover'),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
