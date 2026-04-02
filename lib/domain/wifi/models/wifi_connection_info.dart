import 'package:network_info_plus/network_info_plus.dart';

import '../../tollgate/constants/tollgate_constants.dart';

/// Model representing information about the current WiFi connection
class WifiConnectionInfo {
  /// The SSID of the connected network
  final String? ssid;

  /// The BSSID (MAC address) of the connected access point
  final String? bssid;

  /// The IP address of the connected device
  final String? ipAddress;

  /// The subnet mask of the network
  final String? subnet;

  /// The gateway/router IP address
  final String? gatewayIp;

  /// The broadcast address of the network
  final String? broadcast;

  const WifiConnectionInfo({
    this.ssid,
    this.bssid,
    this.ipAddress,
    this.subnet,
    this.gatewayIp,
    this.broadcast,
  });

  /// Creates a WifiConnectionInfo from NetworkInfo data
  static Future<WifiConnectionInfo> fromNetworkInfo() async {
    final networkInfo = NetworkInfo();

    return WifiConnectionInfo(
      ssid: await networkInfo
          .getWifiName(), // includes quotes that need to be removed
      bssid: await networkInfo.getWifiBSSID(),
      ipAddress: await networkInfo.getWifiIP(),
      subnet: await networkInfo.getWifiSubmask(),
      gatewayIp: await networkInfo.getWifiGatewayIP(),
      broadcast: await networkInfo.getWifiBroadcast(),
    );
  }

  /// Whether there is an active WiFi connection
  bool get isConnected => ssid != null && ipAddress != null;

  /// The SSID without quotes (if present)
  String? get cleanSsid => ssid?.replaceAll('"', '');

  /// Creates a copy of this WifiConnectionInfo with some fields replaced
  WifiConnectionInfo copyWith({
    String? ssid,
    String? bssid,
    String? ipAddress,
    String? subnet,
    String? gatewayIp,
    String? broadcast,
  }) {
    return WifiConnectionInfo(
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      ipAddress: ipAddress ?? this.ipAddress,
      subnet: subnet ?? this.subnet,
      gatewayIp: gatewayIp ?? this.gatewayIp,
      broadcast: broadcast ?? this.broadcast,
    );
  }

  bool get isTollGate => looksLikeTollGateSsid(cleanSsid);

  @override
  String toString() {
    return 'WifiConnectionInfo(ssid: $cleanSsid, ip: $ipAddress, gateway: $gatewayIp)';
  }
}
