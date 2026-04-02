const kTollgateRouterIp = '172.19.217.1';
const kTollgateInfoPort = '2121';
const kTollgatePaymentPort = kTollgateInfoPort;

final RegExp _tollgateSsidPattern = RegExp(
  r'^"?tollgate(?:-[A-Za-z0-9._]+)*"?$',
  caseSensitive: false,
);

bool looksLikeTollGateSsid(String? ssid) {
  if (ssid == null) {
    return false;
  }

  final normalized = ssid.trim();
  return _tollgateSsidPattern.hasMatch(normalized) ||
      normalized.toLowerCase().contains('tollgate');
}
