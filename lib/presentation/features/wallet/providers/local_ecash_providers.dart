import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/config/providers/service_providers.dart';

part 'local_ecash_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<Token?> ecashLocalTokenStream(Ref ref) async* {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  final encoded = await ecashLocalStorage.retrieveLocalEcash();
  if (encoded == null) {
    yield null;
  } else {
    yield Token.parse(encoded: encoded);
  }
}

@Riverpod(keepAlive: true)
Future<void> storeLocalEcash(Ref ref, String encoded) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.storeLocalEcash(encoded);
  ref.invalidate(ecashLocalTokenStreamProvider);
}

@Riverpod(keepAlive: true)
Future<void> clearLocalEcash(Ref ref) async {
  final ecashLocalStorage = ref.watch(ecashLocalStorageProvider);
  await ecashLocalStorage.clearLocalEcash();
  ref.invalidate(ecashLocalTokenStreamProvider);
}
