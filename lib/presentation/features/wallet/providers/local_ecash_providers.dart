import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/config/providers/service_providers.dart';

import '../../../../data/services/wallet/local_ecash_wallet_service.dart';

part 'local_ecash_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<Token?> regularEcashLocalTokenStream(Ref ref) async* {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  final encoded = await ecashLocalStorage.retrieveLocalEcash();
  if (encoded == null) {
    yield null;
  } else {
    yield Token.parse(encoded: encoded);
  }
}

@Riverpod(keepAlive: true)
Stream<Token?> legacySwappedEcashLocalTokenStream(Ref ref) async* {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  final encoded = await ecashLocalStorage.retrieveSwappedEcash();
  if (encoded == null) {
    yield null;
  } else {
    yield Token.parse(encoded: encoded);
  }
}

@Riverpod(keepAlive: true)
Future<BigInt> swappedEcashBalance(Ref ref) async {
  final localEcashWalletService = ref.watch(localEcashWalletServiceProvider);
  final balances = await localEcashWalletService.listPoolBalances();
  var total = BigInt.zero;
  for (final balance in balances) {
    total += balance.amount;
  }
  return total;
}

@Riverpod(keepAlive: true)
Future<List<LocalEcashPendingBalance>> stagingEcashPendingBalances(
    Ref ref) async {
  final localEcashWalletService = ref.watch(localEcashWalletServiceProvider);
  return localEcashWalletService.listStagingBalances();
}

@Riverpod(keepAlive: true)
Future<List<LocalEcashPendingBalance>> swappedEcashPoolBalances(Ref ref) async {
  final localEcashWalletService = ref.watch(localEcashWalletServiceProvider);
  return localEcashWalletService.listPoolBalances();
}

@Riverpod(keepAlive: true)
Future<void> storeLocalEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeLocalEcash(encoded);
  ref.invalidate(regularEcashLocalTokenStreamProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearLocalEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearLocalEcash();
  ref.invalidate(regularEcashLocalTokenStreamProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> storeLegacySwappedEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeSwappedEcash(encoded);
  ref.invalidate(legacySwappedEcashLocalTokenStreamProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearLegacySwappedEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearSwappedEcash();
  ref.invalidate(legacySwappedEcashLocalTokenStreamProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
}
