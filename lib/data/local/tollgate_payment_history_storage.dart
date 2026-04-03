import 'dart:convert';

import 'local_storage_service.dart';

class TollgatePaymentHistoryStorage {
  TollgatePaymentHistoryStorage({required this.localStorageService});

  final LocalStorageService localStorageService;

  static const _key = 'tollgate_payment_history_json';

  List<TollgatePaymentHistoryEntry> load() {
    final raw = localStorageService.getProperty<String>(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    return decoded.whereType<Map>().map((entry) {
      return TollgatePaymentHistoryEntry.fromJson(
        Map<String, dynamic>.from(entry),
      );
    }).toList();
  }

  Future<void> add(TollgatePaymentHistoryEntry entry) async {
    final entries = load();
    final updated = [entry, ...entries].take(100).toList();
    await localStorageService.saveProperty(
      _key,
      jsonEncode(updated.map((entry) => entry.toJson()).toList()),
    );
  }
}

class TollgatePaymentHistoryEntry {
  const TollgatePaymentHistoryEntry({
    required this.id,
    required this.amountSats,
    required this.timestampMs,
    required this.status,
    this.ssid,
    this.dataLabel,
  });

  factory TollgatePaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TollgatePaymentHistoryEntry(
      id: json['id']?.toString() ?? '',
      amountSats: int.tryParse(json['amountSats']?.toString() ?? '') ?? 0,
      timestampMs: int.tryParse(json['timestampMs']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'accepted',
      ssid: json['ssid']?.toString(),
      dataLabel: json['dataLabel']?.toString(),
    );
  }

  final String id;
  final int amountSats;
  final int timestampMs;
  final String status;
  final String? ssid;
  final String? dataLabel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amountSats': amountSats,
      'timestampMs': timestampMs,
      'status': status,
      if (ssid != null) 'ssid': ssid,
      if (dataLabel != null) 'dataLabel': dataLabel,
    };
  }
}
