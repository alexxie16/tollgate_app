import 'local_storage_service.dart';

class EcashLocalStorage {
  final LocalStorageService localPropertiesService;

  EcashLocalStorage({required this.localPropertiesService});

  Future<void> storeLocalEcash(String encoded) async {
    await localPropertiesService.saveProperty('ecash_encoded', encoded);
  }

  Future<String?> retrieveLocalEcash() async {
    return localPropertiesService.getProperty<String>('ecash_encoded');
  }

  Future<void> clearLocalEcash() async {
    await localPropertiesService.removeProperty('ecash_encoded');
  }
}
