import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/providers/repository_providers.dart';

final walletTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final walletRepository = await ref.watch(walletRepositoryProvider.future);
  final transactions = await walletRepository.listTransactions();
  transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return transactions;
});
