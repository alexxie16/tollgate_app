import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tollgate_app/domain/tollgate/constants/tollgate_constants.dart';
import 'package:tollgate_app/domain/tollgate/errors/tollgate_errors.dart';
import 'package:tollgate_app/domain/tollgate/errors/tollgate_payment_submission_error.dart';

import '../../../core/result/result.dart';
import '../../../domain/tollgate/models/tollgate_info.dart';
import '../../../domain/tollgate/models/tollgate_payment_response.dart';
import '../../../domain/tollgate/models/tollgate_usage.dart';

class TollgateService {
  final String _defaultPort;

  TollgateService({String defaultPort = kTollgateInfoPort})
      : _defaultPort = defaultPort;

  /// Fetches Tollgate information from the router
  ///
  /// [routerIp] is the IP address of the router, e.g., '192.168.1.1'
  /// [port] is optional and defaults to '2121'
  Future<Result<TollGateInfo, TollgateInfoRetrievalError>> getTollgateInfo(
      {required String routerIp, String? port = kTollgateInfoPort}) async {
    final targetPort = port ?? _defaultPort;
    final url = 'http://$routerIp:$targetPort';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Connection timed out'),
          );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return Result.ok(TollGateInfo.fromJson(jsonData));
      } else {
        return Result.failure(
          TollgateInfoRetrievalError.failedToGetTollgateInfo(
              'Failed to load Tollgate info: HTTP ${response.statusCode}'),
        );
      }
    } catch (e) {
      debugPrint('Error fetching Tollgate info: $e');
      return Result.failure(
        TollgateInfoRetrievalError.failedToGetTollgateInfo(
            'Failed to connect to Tollgate: ${e.toString()}'),
      );
    }
  }

  /// Detects if the current WiFi is a Tollgate network by attempting to connect to the service
  ///
  /// [routerIp] is the default gateway IP address
  /// Returns true if a Tollgate service is detected
  Future<Result<bool, TollgateInfoRetrievalError>> detectTollgate(
      {required String routerIp, String? port = kTollgateInfoPort}) async {
    final result = await getTollgateInfo(routerIp: routerIp, port: port);

    return result
        .map(
      (info) => true, // If we got info, it's a Tollgate
    )
        .mapFailure(
      (error) {
        // If it's a connection error, it may not be a Tollgate
        return TollgateInfoRetrievalError.failedToGetTollgateInfo(
            'Not a Tollgate network');
      },
    );
  }

  Future<Result<TollGatePaymentResponse, TollgatePaymentSubmissionError>>
      submitEcashToken({
    required String cashuToken,
    String? authToken,
    String routerIp = kTollgateRouterIp,
    String port = kTollgatePaymentPort,
  }) async {
    final uri = Uri.parse('http://$routerIp:$port/');

    try {
      debugPrint('TollGate payment URL: $uri');
      debugPrint('TollGate payment payload: $cashuToken');

      final response = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json, text/plain, */*',
            },
            body: cashuToken,
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Connection timed out'),
          );

      debugPrint(
          'TollGate payment response: ${response.statusCode} ${response.body}');

      final parsedBody = _decodeJsonMap(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (parsedBody != null) {
          return Result.ok(TollGatePaymentResponse.fromJson(parsedBody));
        }

        return Result.ok(
          TollGatePaymentResponse(
            status: 'accepted',
            raw: {'body': response.body},
          ),
        );
      }

      if (parsedBody != null) {
        final paymentResponse = TollGatePaymentResponse.fromJson(parsedBody);
        return Result.failure(
          TollgatePaymentSubmissionError(paymentResponse.userMessage),
        );
      }

      return Result.failure(
        TollgatePaymentSubmissionError(
          'TollGate payment failed: HTTP ${response.statusCode}',
        ),
      );
    } catch (e) {
      debugPrint('Error submitting TollGate payment to $uri: $e');
      return Result.failure(
        TollgatePaymentSubmissionError(
          'Failed to submit the eCash token: ${e.toString()}',
        ),
      );
    }
  }

  Future<Result<TollGateUsage, TollgateInfoRetrievalError>> getTollgateUsage({
    String routerIp = kTollgateRouterIp,
    String port = kTollgateInfoPort,
  }) async {
    final uri = Uri.parse('http://$routerIp:$port/usage');

    try {
      final response = await http.get(uri).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Connection timed out'),
          );

      if (response.statusCode != 200) {
        return Result.failure(
          TollgateInfoRetrievalError.failedToGetTollgateInfo(
            'Failed to load Tollgate usage: HTTP ${response.statusCode}',
          ),
        );
      }

      final usage = _parseUsage(response.body);
      if (usage == null) {
        return Result.failure(
          TollgateInfoRetrievalError.failedToGetTollgateInfo(
            'Failed to parse Tollgate usage response.',
          ),
        );
      }

      return Result.ok(usage);
    } catch (e) {
      debugPrint('Error fetching Tollgate usage: $e');
      return Result.failure(
        TollgateInfoRetrievalError.failedToGetTollgateInfo(
          'Failed to connect to Tollgate usage endpoint: ${e.toString()}',
        ),
      );
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  TollGateUsage? _parseUsage(String body) {
    final trimmed = body.trim();
    final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(trimmed);
    if (match != null) {
      return TollGateUsage(
        usedBytes: BigInt.parse(match.group(1)!),
        allocatedBytes: BigInt.parse(match.group(2)!),
      );
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final used = decoded['used'] ?? decoded['usedBytes'];
        final allocated = decoded['allocated'] ?? decoded['allocatedBytes'];
        if (used != null && allocated != null) {
          return TollGateUsage(
            usedBytes: BigInt.parse(used.toString()),
            allocatedBytes: BigInt.parse(allocated.toString()),
          );
        }
      }
    } catch (_) {}

    return null;
  }
}
