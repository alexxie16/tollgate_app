import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../config/providers/service_providers.dart';
import '../../../../domain/tollgate/errors/tollgate_errors.dart';
import '../../../../domain/tollgate/models/tollgate_info.dart';
import '../../../../domain/tollgate/models/tollgate_usage.dart';
import '../../../../core/result/result.dart';

part 'tollgate_providers.g.dart';

@riverpod
Future<Result<TollGateInfo, TollgateInfoRetrievalError>> tollgateInfo(
  Ref ref,
  String routerIp,
) async {
  final tollgateService = ref.read(tollgateServiceProvider);
  return await tollgateService.getTollgateInfo(routerIp: routerIp);
}

@riverpod
Future<Result<bool, TollgateInfoRetrievalError>> isTollgateNetwork(
  Ref ref,
  String routerIp,
) async {
  final tollgateService = ref.read(tollgateServiceProvider);
  return await tollgateService.detectTollgate(routerIp: routerIp);
}

@riverpod
Stream<Result<TollGateUsage, TollgateInfoRetrievalError>> tollgateUsage(
  Ref ref,
  String routerIp,
) async* {
  final tollgateService = ref.read(tollgateServiceProvider);

  while (true) {
    yield await tollgateService.getTollgateUsage(routerIp: routerIp);
    await Future.delayed(const Duration(seconds: 5));
  }
}

// Tollgate state to track payments and time
class TollgateState {
  final TollGateInfo? tollgateInfo;
  final bool isPaid;
  final DateTime? expiresAt;
  final bool autoRenewEnabled;
  final int amountPaidSats;
  final String? errorMessage;
  final bool isLoading;

  const TollgateState({
    this.tollgateInfo,
    this.isPaid = false,
    this.expiresAt,
    this.autoRenewEnabled = false,
    this.amountPaidSats = 0,
    this.errorMessage,
    this.isLoading = false,
  });

  int get timeLeftSeconds {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.inSeconds > 0 ? diff.inSeconds : 0;
  }

  int get timeLeftMinutes => (timeLeftSeconds / 60).ceil();

  TollgateState copyWith({
    TollGateInfo? tollgateInfo,
    bool? isPaid,
    DateTime? expiresAt,
    bool? autoRenewEnabled,
    int? amountPaidSats,
    String? errorMessage,
    bool? isLoading,
  }) {
    return TollgateState(
      tollgateInfo: tollgateInfo ?? this.tollgateInfo,
      isPaid: isPaid ?? this.isPaid,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenewEnabled: autoRenewEnabled ?? this.autoRenewEnabled,
      amountPaidSats: amountPaidSats ?? this.amountPaidSats,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(keepAlive: true)
class TollgateStateNotifier extends _$TollgateStateNotifier {
  @override
  TollgateState build() {
    return const TollgateState();
  }

  // Initialize with Tollgate info
  Future<void> initialize(String routerIp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await ref
        .read(tollgateServiceProvider)
        .getTollgateInfo(routerIp: routerIp);

    result.fold(
      onSuccess: (info) {
        state = state.copyWith(
          tollgateInfo: info,
          isLoading: false,
        );
      },
      onFailure: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.message,
        );
      },
    );
  }

  // Set payment status and expiration
  void setPayment({
    required bool isPaid,
    required DateTime expiresAt,
    required int amountPaidSats,
  }) {
    state = state.copyWith(
      isPaid: isPaid,
      expiresAt: expiresAt,
      amountPaidSats: amountPaidSats,
      errorMessage: null,
    );
  }

  // Toggle auto-renew setting
  void toggleAutoRenew() {
    state = state.copyWith(
      autoRenewEnabled: !state.autoRenewEnabled,
    );
  }

  // Add more time to the current session
  void addTime(int additionalMinutes, int additionalPaymentSats) {
    final currentExpiry = state.expiresAt ?? DateTime.now();
    final newExpiry = currentExpiry.add(Duration(minutes: additionalMinutes));

    state = state.copyWith(
      expiresAt: newExpiry,
      amountPaidSats: state.amountPaidSats + additionalPaymentSats,
    );
  }

  // Reset all payment information
  void reset() {
    state = const TollgateState();
  }
}
