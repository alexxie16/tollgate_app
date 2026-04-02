import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/core/result/result.dart';
import 'package:tollgate_app/presentation/common/extensions/async_value_x.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/widgets/snackbar/app_snackbar.dart';

import '../../../../domain/wifi/models/wifi_network.dart';
import '../../../router/routes.dart';
import '../../tollgate/interactors/tollgate_interactor.dart';
import '../../wifi/providers/scan_networks_stream_provider.dart';
import '../constants/home_constants.dart';
import '../../wifi/widgets/network_card.dart';

class AvailableTollgateNetworksCard extends ConsumerWidget {
  const AvailableTollgateNetworksCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networksAsync = ref.watch(scanNetworksStreamProvider).flatten;

    return networksAsync.when(
      data: (networks) {
        return _buildCard(context, ref, networks: networks);
      },
      loading: () => SizedBox(
        height: 180,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Future<void> _connectToNetwork(
    BuildContext context,
    WidgetRef ref, {
    required WiFiNetwork network,
  }) async {
    final result = await TollgateInteractor(ref).connectAndLoadPricing(network);
    if (!context.mounted) return;

    switch (result) {
      case Ok(value: final value):
        AppSnackBar.showSuccess(
          context,
          message: 'Connected to ${network.ssid}',
        );
        context.push('${Routes.home}payment', extra: {
          'ssid': value.connectionInfo.cleanSsid ?? network.ssid,
          'tollgateInfo': value.tollgateInfo,
        });
      case Failure(failure: final failure):
        AppSnackBar.showError(context, message: failure);
    }
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref, {
    required List<WiFiNetwork> networks,
  }) {
    final tollGateNetworks =
        networks.where((network) => network.isTollGate).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Available TollGate Networks:',
          style: context.textTheme.labelMedium?.copyWith(
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (tollGateNetworks.isEmpty)
          Text(
            'No TollGate Networks Found',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface,
            ),
          )
        else ...[
          ...tollGateNetworks.take(homeScreenMaxNetworksToShow).map(
                (network) => NetworkCard(
                  network: network,
                  onTap: () => _connectToNetwork(
                    context,
                    ref,
                    network: network,
                  ),
                ),
              ),
          if (tollGateNetworks.length > homeScreenMaxNetworksToShow)
            TextButton(
              onPressed: () => context.go(Routes.scan),
              child: Text(
                '+${tollGateNetworks.length - homeScreenMaxNetworksToShow} TollGate Networks',
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(Routes.scan),
            child: const Text('More Networks'),
          ),
        ),
      ],
    );
  }
}
