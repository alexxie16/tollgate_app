import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/providers/service_providers.dart';
import '../../../../data/local/tollgate_payment_history_storage.dart';
import 'wallet_transactions_provider.dart';

sealed class WalletHistoryEntry {
  const WalletHistoryEntry();

  DateTime get timestamp;
}

class WalletTransactionHistoryEntry extends WalletHistoryEntry {
  const WalletTransactionHistoryEntry(this.transaction);

  final Transaction transaction;

  @override
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(
        transaction.timestamp.toInt() * 1000,
        isUtc: true,
      ).toLocal();
}

class TollgatePaymentHistoryEntryView extends WalletHistoryEntry {
  const TollgatePaymentHistoryEntryView(this.entry);

  final TollgatePaymentHistoryEntry entry;

  @override
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(entry.timestampMs).toLocal();
}

final walletHistoryProvider =
    FutureProvider<List<WalletHistoryEntry>>((ref) async {
  final walletTransactions = await ref.watch(walletTransactionsProvider.future);
  final tollgateHistory =
      ref.watch(tollgatePaymentHistoryStorageProvider).load();

  final entries = <WalletHistoryEntry>[
    ...walletTransactions.map(WalletTransactionHistoryEntry.new),
    ...tollgateHistory.map(TollgatePaymentHistoryEntryView.new),
  ];

  entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return entries;
});
