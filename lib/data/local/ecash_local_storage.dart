import 'local_storage_service.dart';

class EcashLocalStorage {
  final LocalStorageService localPropertiesService;

  EcashLocalStorage({required this.localPropertiesService});

  static const _regularEcashKey = 'ecash_encoded';
  static const _swappedEcashKey = 'ecash_swapped_encoded';

  Future<void> storeLocalEcash(String encoded) async {
    await localPropertiesService.saveProperty(_regularEcashKey, encoded);
  }

  Future<String?> retrieveLocalEcash() async {
    return localPropertiesService.getProperty<String>(_regularEcashKey);
  }

  Future<void> clearLocalEcash() async {
    await localPropertiesService.removeProperty(_regularEcashKey);
  }

  Future<void> storeSwappedEcash(String encoded) async {
    await localPropertiesService.saveProperty(_swappedEcashKey, encoded);
  }

  Future<String?> retrieveSwappedEcash() async {
    return localPropertiesService.getProperty<String>(_swappedEcashKey);
  }

  Future<void> clearSwappedEcash() async {
    await localPropertiesService.removeProperty(_swappedEcashKey);
  }
}
