import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/wallet_transactions_provider.dart';

class RecentTransactionsWidget extends ConsumerWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(walletTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        switch (transactionsAsync) {
          AsyncData(:final value) => value.isEmpty
              ? const EmptyTransactionsList()
              : TransactionsList(transactions: value.take(8).toList()),
          AsyncError(:final error) => TransactionErrorState(
              error: error,
              onRetry: () => ref.invalidate(walletTransactionsProvider),
            ),
          _ => const TransactionsLoadingState(),
        },
      ],
    );
  }
}

class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    required this.transactions,
  });

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: transactions
          .map(
            (transaction) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      _transactionColor(transaction.direction).withAlpha(25),
                  child: Icon(
                    _transactionIcon(transaction.direction),
                    color: _transactionColor(transaction.direction),
                  ),
                ),
                title: Text(
                  _transactionTitle(transaction),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Text(
                  '${_formatTimestamp(transaction.timestamp)} • ${transaction.mintUrl}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${transaction.direction == TransactionDirection.incoming ? '+' : '-'}${transaction.amount} sats',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _transactionColor(transaction.direction),
                          ),
                    ),
                    Text(
                      transaction.status.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static IconData _transactionIcon(TransactionDirection direction) {
    return direction == TransactionDirection.incoming
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
  }

  static Color _transactionColor(TransactionDirection direction) {
    return direction == TransactionDirection.incoming
        ? Colors.green
        : Colors.orange;
  }

  static String _transactionTitle(Transaction transaction) {
    if (transaction.memo?.trim().isNotEmpty ?? false) {
      return transaction.memo!.trim();
    }

    return transaction.direction == TransactionDirection.incoming
        ? 'Incoming Cashu transaction'
        : 'Outgoing Cashu transaction';
  }

  static String _formatTimestamp(BigInt timestamp) {
    final raw = timestamp.toInt();
    final millis = raw > 9999999999 ? raw : raw * 1000;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${dateTime.year}-${twoDigits(dateTime.month)}-${twoDigits(dateTime.day)} ${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
  }
}

class EmptyTransactionsList extends StatelessWidget {
  const EmptyTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionsLoadingState extends StatelessWidget {
  const TransactionsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class TransactionErrorState extends StatelessWidget {
  const TransactionErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            'Unable to load recent transactions',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          Text(
            error.toString(),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
