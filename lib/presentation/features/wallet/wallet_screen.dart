import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/providers/connectivity_stream_provider.dart';
import 'package:tollgate_app/presentation/router/routes.dart';

import 'widgets/action_card.dart';
import 'widgets/balance_card.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasInternet =
        ref.watch(connectivityStreamProvider).valueOrNull ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                if (!hasInternet) ...[
                  _buildOfflineNotice(context),
                  const SizedBox(height: 16),
                ],
                const BalanceCard(),
                const SizedBox(height: 16),
                _buildActionCards(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Offline mode: Send and TollGate still work with stored local eCash. Creating invoices and swapping regular eCash into swapped eCash need internet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            ActionCard(
              icon: Icons.arrow_upward_rounded,
              title: 'Send',
              subtitle: 'Create a token from local eCash',
              color: Colors.blue,
              onTap: () {
                context.go(Routes.send);
              },
            ),
            ActionCard(
              icon: Icons.arrow_downward_rounded,
              title: 'Receive',
              subtitle: 'Paste token or create invoice',
              color: Colors.green,
              onTap: () {
                context.go(Routes.receive);
              },
            ),
          ],
        ),
      ],
    );
  }
}
