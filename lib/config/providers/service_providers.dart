import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/cashu_local_preferences.dart';
import '../../data/local/ecash_local_storage.dart';
import '../../data/services/tollgate/tollgate_service.dart';
import '../../data/services/wallet/local_ecash_wallet_service.dart';
import '../../data/services/wifi/wifi_service.dart';
import '../storage/local_storage_service_provider.dart';

part 'service_providers.g.dart';

@riverpod
WifiService wifiService(Ref ref) => WifiService();

@riverpod
TollgateService tollgateService(Ref ref) => TollgateService();

@Riverpod(keepAlive: true)
CashuLocalPreferences cashuLocalPreferences(Ref ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  return CashuLocalPreferences(localPropertiesService: storageService);
}

@Riverpod(keepAlive: true)
EcashLocalStorage ecashLocalStorage(Ref ref) {
  final storageService = ref.watch(localStorageServiceProvider);
  return EcashLocalStorage(localPropertiesService: storageService);
}

@Riverpod(keepAlive: true)
LocalEcashWalletService localEcashWalletService(Ref ref) =>
    LocalEcashWalletService();
