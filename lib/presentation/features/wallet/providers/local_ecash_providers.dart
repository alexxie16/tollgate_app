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
Stream<Token?> swappedEcashLocalTokenStream(Ref ref) async* {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  final encoded = await ecashLocalStorage.retrieveSwappedEcash();
  if (encoded == null) {
    yield null;
  } else {
    yield Token.parse(encoded: encoded);
  }
}

@Riverpod(keepAlive: true)
Stream<Token?> ecashLocalTokenStream(Ref ref) async* {
  final swappedToken =
      await ref.watch(swappedEcashLocalTokenStreamProvider.future);
  if (swappedToken != null) {
    yield swappedToken;
    return;
  }

  yield await ref.watch(regularEcashLocalTokenStreamProvider.future);
}

@Riverpod(keepAlive: true)
Future<List<LocalEcashPendingBalance>> localEcashPendingBalances(
    Ref ref) async {
  final localEcashWalletService = ref.watch(localEcashWalletServiceProvider);
  return localEcashWalletService.listPendingBalances();
}

@Riverpod(keepAlive: true)
Future<void> storeLocalEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeLocalEcash(encoded);
  ref.invalidate(regularEcashLocalTokenStreamProvider);
  ref.invalidate(ecashLocalTokenStreamProvider);
  ref.invalidate(localEcashPendingBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearLocalEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearLocalEcash();
  ref.invalidate(regularEcashLocalTokenStreamProvider);
  ref.invalidate(ecashLocalTokenStreamProvider);
  ref.invalidate(localEcashPendingBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> storeSwappedEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeSwappedEcash(encoded);
  ref.invalidate(swappedEcashLocalTokenStreamProvider);
  ref.invalidate(ecashLocalTokenStreamProvider);
  ref.invalidate(localEcashPendingBalancesProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearSwappedEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearSwappedEcash();
  ref.invalidate(swappedEcashLocalTokenStreamProvider);
  ref.invalidate(ecashLocalTokenStreamProvider);
  ref.invalidate(localEcashPendingBalancesProvider);
}
