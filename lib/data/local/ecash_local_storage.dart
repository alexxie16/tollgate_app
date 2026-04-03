import 'dart:convert';

import 'local_storage_service.dart';

class EcashLocalStorage {
  final LocalStorageService localPropertiesService;

  EcashLocalStorage({required this.localPropertiesService});

  static const _regularEcashKey = 'ecash_encoded';
  static const _swappedEcashKey = 'ecash_swapped_encoded';
  static const _swappedOneSatTokensKey = 'ecash_swapped_one_sat_tokens_json';

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

  Future<void> storeSwappedOneSatTokens(List<String> encodedTokens) async {
    await localPropertiesService.saveProperty(
      _swappedOneSatTokensKey,
      jsonEncode(encodedTokens),
    );
  }

  List<String> retrieveSwappedOneSatTokens() {
    final raw =
        localPropertiesService.getProperty<String>(_swappedOneSatTokensKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {}

    return const [];
  }

  Future<void> clearSwappedOneSatTokens() async {
    await localPropertiesService.removeProperty(_swappedOneSatTokensKey);
  }
}
