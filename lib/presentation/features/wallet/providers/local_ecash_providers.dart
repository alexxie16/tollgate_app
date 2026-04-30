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

final regularEcashBalanceProvider = FutureProvider<BigInt>((ref) async {
  final regularToken =
      await ref.watch(regularEcashLocalTokenStreamProvider.future);
  final stagingBalances =
      await ref.watch(stagingEcashPendingBalancesProvider.future);

  final stagingTotal = stagingBalances.fold<BigInt>(
    BigInt.zero,
    (total, balance) => total + balance.amount,
  );

  return (regularToken?.amount ?? BigInt.zero) + stagingTotal;
});

@Riverpod(keepAlive: true)
Future<BigInt> swappedEcashBalance(Ref ref) async {
  final poolBalances = await ref.watch(swappedEcashPoolBalancesProvider.future);
  final storedOneSatTokens =
      await ref.watch(swappedEcashOneSatTokensProvider.future);
  final legacySwappedToken =
      await ref.watch(legacySwappedEcashLocalTokenStreamProvider.future);

  final poolTotal = poolBalances.fold<BigInt>(
    BigInt.zero,
    (total, balance) => total + balance.amount,
  );
  final storedTokenTotal = storedOneSatTokens.fold<BigInt>(
    BigInt.zero,
    (total, token) => total + token.amount,
  );

  return poolTotal +
      storedTokenTotal +
      (legacySwappedToken?.amount ?? BigInt.zero);
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
Future<List<Token>> swappedEcashOneSatTokens(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  return ecashLocalStorage
      .retrieveSwappedOneSatTokens()
      .map((encoded) => Token.parse(encoded: encoded))
      .toList();
}

@Riverpod(keepAlive: true)
Future<void> storeLocalEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeLocalEcash(encoded);
  ref.invalidate(regularEcashLocalTokenStreamProvider);
  ref.invalidate(regularEcashBalanceProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
  ref.invalidate(swappedEcashOneSatTokensProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearLocalEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearLocalEcash();
  ref.invalidate(regularEcashLocalTokenStreamProvider);
  ref.invalidate(regularEcashBalanceProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
  ref.invalidate(swappedEcashOneSatTokensProvider);
}

@Riverpod(keepAlive: true)
Future<void> storeLegacySwappedEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeSwappedEcash(encoded);
  ref.invalidate(legacySwappedEcashLocalTokenStreamProvider);
  ref.invalidate(regularEcashBalanceProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
  ref.invalidate(swappedEcashOneSatTokensProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearLegacySwappedEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearSwappedEcash();
  ref.invalidate(legacySwappedEcashLocalTokenStreamProvider);
  ref.invalidate(regularEcashBalanceProvider);
  ref.invalidate(stagingEcashPendingBalancesProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
  ref.invalidate(swappedEcashOneSatTokensProvider);
}

@Riverpod(keepAlive: true)
Future<void> storeSwappedOneSatTokens(
    Ref ref, List<String> encodedTokens) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeSwappedOneSatTokens(encodedTokens);
  ref.invalidate(swappedEcashOneSatTokensProvider);
  ref.invalidate(regularEcashBalanceProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearSwappedOneSatTokens(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearSwappedOneSatTokens();
  ref.invalidate(swappedEcashOneSatTokensProvider);
  ref.invalidate(regularEcashBalanceProvider);
  ref.invalidate(swappedEcashBalanceProvider);
  ref.invalidate(swappedEcashPoolBalancesProvider);
}
