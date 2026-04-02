import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/async_value_x.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/providers/connectivity_stream_provider.dart';

import '../../../domain/tollgate/constants/tollgate_constants.dart';
import '../../../domain/wifi/models/wifi_connection_info.dart';
import '../tollgate/providers/tollgate_providers.dart';
import '../wifi/providers/current_connection_state_stream_provider.dart';
import 'widgets/available_tollgate_networks_card.dart';
import 'widgets/connected_non_tollgate_card.dart';
import 'widgets/connected_tollgate_card.dart';
import 'widgets/connection_status_card.dart';
import 'widgets/wallet_card.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConnectionStateAsync =
        ref.watch(currentConnectionStateStreamProvider);
    final hasInternet =
        ref.watch(connectivityStreamProvider).valueOrNull ?? false;

    return currentConnectionStateAsync.when(
      data: (currentConnectionState) => Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  if (!hasInternet) ...[
                    _buildOfflineNotice(context),
                    const SizedBox(height: 20),
                  ],
                  // Connection Status Card
                  _buildWifiConnectionSection(
                    context,
                    ref,
                    currentConnectionState: currentConnectionState,
                    hasInternet: hasInternet,
                  ),
                  const SizedBox(height: 30),
                  // Wallet Card
                  const WalletCard(),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context),
                  _buildOfflineNotice(context,
                      message:
                          'The app could not refresh the current connection state. Local wallet features still work offline.'),
                  const SizedBox(height: 20),
                  ConnectionStatusCard(
                    connectionInfo: null,
                    hasInternet: hasInternet,
                    isTollGate: false,
                  ),
                  const SizedBox(height: 30),
                  const WalletCard(),
                ],
              ),
            ),
          ),
        ),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Center(
              child: SvgPicture.asset(
                isDarkMode
                    ? 'assets/images/tollgate_logo_white.svg'
                    : 'assets/images/tollgate_logo_black.svg',
                width: 190,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Text(
            'Pay-as-You-Go Internet with Bitcoin',
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineNotice(BuildContext context,
      {String message =
          'Internet is currently unavailable. Local eCash and TollGate payment can still work with already stored tokens.'}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, color: context.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiConnectionSection(
    BuildContext context,
    WidgetRef ref, {
    required CurrentConnectionState currentConnectionState,
    required bool hasInternet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wi-Fi Connection',
          style: context.textTheme.titleMedium?.copyWith(
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ConnectionStatusCard(
          connectionInfo: currentConnectionState.connectionInfo,
          hasInternet: hasInternet,
          isTollGate:
              currentConnectionState.connectionInfo?.isTollGate ?? false,
        ),
        const SizedBox(height: 20),
        if (currentConnectionState.connectionInfo != null)
          if (currentConnectionState.connectionInfo!.isTollGate)
            _buildTollgateCard(
              ref,
              connectionInfo: currentConnectionState.connectionInfo!,
              hasInternet: hasInternet,
            )
          else
            ConnectedNonTollgateCard(
              ssid: currentConnectionState.connectionInfo!.ssid ??
                  'Unknown Network',
            )
        else
          const AvailableTollgateNetworksCard(),
      ],
    );
  }

  Widget _buildTollgateCard(
    WidgetRef ref, {
    required WifiConnectionInfo connectionInfo,
    required bool hasInternet,
  }) {
    final tollGateInfoAsync =
        ref.watch(tollgateInfoProvider(kTollgateRouterIp)).flatten;

    return tollGateInfoAsync.when(
      data: (tollGateInfo) => ConnectedTollgateCard(
        ssid: connectionInfo.ssid ?? 'Unknown Network',
        tollgateInfo: tollGateInfo,
        hasInternet: hasInternet,
      ),
      error: (error, stack) => ConnectedNonTollgateCard(
        ssid: connectionInfo.ssid ?? 'Unknown Network',
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
