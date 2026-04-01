import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/router/routes.dart';

import 'widgets/action_card.dart';
import 'widgets/balance_card.dart';
import 'widgets/secondary_action_card.dart';
import 'widgets/recent_transactions_widget.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement QR scan
        },
        backgroundColor: Colors.purple,
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 28),
                const BalanceCard(),
                const SizedBox(height: 16),
                _buildActionCards(context),
                const SizedBox(height: 24),
                const RecentTransactionsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    final actionColors = {
      'send': Colors.blue,
      'receive': Colors.green,
      'mint': Colors.orange,
      'melt': Colors.red,
      'reserve': Colors.purple,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Actions - Top Row
        Text(
          'Primary Actions',
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
            // Mint Button
            ActionCard(
              icon: Icons.local_atm_rounded,
              title: 'Mint',
              subtitle: 'Add funds to wallet',
              color: actionColors['mint']!,
              onTap: () {
                context.go(Routes.mint);
              },
            ),

            // Reserve Button (New)
            ActionCard(
              icon: Icons.offline_bolt_rounded,
              title: 'Reserve',
              subtitle: 'Store offline ecash for TollGate',
              color: actionColors['reserve']!,
              onTap: () {
                context.go(Routes.reserve);
              },
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Secondary Actions - Bottom Row
        Text(
          'Other Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            // Send Button
            SecondaryActionCard(
              icon: Icons.arrow_upward_rounded,
              title: 'Send',
              color: actionColors['send']!,
              onTap: () {
                context.go(Routes.send);
              },
            ),

            // Receive Button
            SecondaryActionCard(
              icon: Icons.arrow_downward_rounded,
              title: 'Receive',
              color: actionColors['receive']!,
              onTap: () {
                context.go(Routes.receive);
              },
            ),

            // Melt Button
            SecondaryActionCard(
              icon: Icons.currency_bitcoin,
              title: 'Melt',
              color: actionColors['melt']!,
              onTap: () {
                // TODO: Navigate to melt screen
              },
            ),
          ],
        ),
      ],
    );
  }
}
