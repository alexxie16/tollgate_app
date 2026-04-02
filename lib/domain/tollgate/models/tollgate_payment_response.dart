class TollGatePaymentResponse {
  const TollGatePaymentResponse({
    required this.status,
    this.authToken,
    this.error,
    this.raw = const {},
  });

  factory TollGatePaymentResponse.fromJson(Map<String, dynamic> json) {
    final authToken = json['authToken']?.toString();
    return TollGatePaymentResponse(
      status: json['status']?.toString() ??
          ((authToken != null && authToken.isNotEmpty)
              ? 'accepted'
              : 'unknown'),
      authToken: authToken,
      error: json['error']?.toString(),
      raw: json,
    );
  }

  final String status;
  final String? authToken;
  final String? error;
  final Map<String, dynamic> raw;

  bool get isAccepted => status.toLowerCase() == 'accepted';

  String get userMessage {
    if (isAccepted) {
      return 'accepted';
    }

    if (error != null && error!.trim().isNotEmpty) {
      return error!;
    }

    return 'The TollGate rejected the payment.';
  }
}
