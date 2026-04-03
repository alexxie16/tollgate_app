import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';

import '../providers/wallet_transactions_provider.dart';

class RecentTransactionsWidget extends ConsumerWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _InfoCard(
            title: 'History',
            message: 'No wallet transactions yet.',
          );
        }

        final visibleTransactions = transactions.take(8).toList();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Transactions',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...visibleTransactions.map(
                (tx) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TransactionRow(transaction: tx),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _InfoCard(
        title: 'History unavailable',
        message: error.toString(),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.direction == TransactionDirection.incoming;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      transaction.timestamp.toInt() * 1000,
      isUtc: true,
    ).toLocal();

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isIncoming
              ? Colors.green.withAlpha(20)
              : Colors.orange.withAlpha(20),
          child: Icon(
            isIncoming ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: isIncoming ? Colors.green : Colors.orange,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isIncoming ? 'Incoming' : 'Outgoing',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('MMM d, HH:mm').format(timestamp),
                style: context.textTheme.bodySmall,
              ),
              if (transaction.memo != null && transaction.memo!.isNotEmpty)
                Text(
                  transaction.memo!,
                  style: context.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Text(
          '${isIncoming ? '+' : '-'}${transaction.amount} sats',
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isIncoming ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(message, style: context.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
