import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/extensions/tollgate_info_x.dart';
import 'package:tollgate_app/presentation/common/widgets/snackbar/app_snackbar.dart';
import 'package:tollgate_app/presentation/router/routes.dart';

import '../../../../domain/tollgate/models/tollgate_info.dart';
import '../../wallet/providers/wallet_balance_stream_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? networkData;

  const PaymentScreen({
    super.key,
    this.networkData,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _selectedPackage = 1;
  final TextEditingController _customAmountController = TextEditingController();

  final List<_TimePackage> _packages = const [
    _TimePackage(label: '5 mins', minutes: 5, icon: Icons.timelapse),
    _TimePackage(label: '15 mins', minutes: 15, icon: Icons.timer),
    _TimePackage(label: '1 hour', minutes: 60, icon: Icons.hourglass_bottom),
    _TimePackage(label: 'Custom', minutes: null, icon: Icons.edit),
  ];

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  TollGateInfo? _extractTollgateInfo(Map<String, dynamic> networkData) {
    final tollgateInfo = networkData['tollgateInfo'];
    return tollgateInfo is TollGateInfo ? tollgateInfo : null;
  }

  bool _supportsTimeMetric(TollGateInfo? tollgateInfo) {
    if (tollgateInfo == null) {
      return false;
    }

    return const ['milliseconds', 'seconds', 'minutes', 'hours']
        .contains(tollgateInfo.metric.toLowerCase());
  }

  int? _packagePrice(TollGateInfo? tollgateInfo, int packageIndex) {
    if (packageIndex == 3) {
      return int.tryParse(_customAmountController.text.trim());
    }

    if (!_supportsTimeMetric(tollgateInfo)) {
      return null;
    }

    final minutes = _packages[packageIndex].minutes;
    if (minutes == null) {
      return null;
    }

    return tollgateInfo!.calculatePrice(minutes: minutes);
  }

  Future<void> _showPaymentUnavailable(TollGateInfo? tollgateInfo) async {
    final message = tollgateInfo == null
        ? 'Connect to a TollGate network first to load live pricing.'
        : 'Live pricing is loaded, but TollGate payment submission is not implemented in the app yet.';
    AppSnackBar.showInfo(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final networkData = widget.networkData ?? <String, dynamic>{};
    final tollgateInfo = _extractTollgateInfo(networkData);
    final ssid = networkData['ssid'] as String? ?? 'Unknown Network';
    final selectedPrice = _packagePrice(tollgateInfo, _selectedPackage);
    final walletBalanceAsync = ref.watch(walletBalanceStreamProvider);
    final walletBalance = walletBalanceAsync.valueOrNull ?? BigInt.zero;
    final hasEnoughBalance =
        selectedPrice != null && walletBalance >= BigInt.from(selectedPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TollGate Pricing'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NetworkSummaryCard(
              ssid: ssid,
              tollgateInfo: tollgateInfo,
            ),
            const SizedBox(height: 16),
            if (tollgateInfo == null)
              const _InfoCard(
                title: 'Pricing unavailable',
                message:
                    'This screen only shows live TollGate pricing when opened from a connected TollGate network.',
                icon: Icons.info_outline,
              )
            else if (!_supportsTimeMetric(tollgateInfo))
              _InfoCard(
                title: 'Metric not supported yet',
                message:
                    'The connected router bills in ${tollgateInfo.metric}. The app currently only supports time-based TollGate pricing review.',
                icon: Icons.warning_amber_rounded,
              )
            else
              _buildPackageSelector(tollgateInfo),
            const SizedBox(height: 16),
            _WalletBalanceCard(
              walletBalanceAsync: walletBalanceAsync,
              selectedPrice: selectedPrice,
              hasEnoughBalance: hasEnoughBalance,
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              title: 'Payment flow status',
              message:
                  'This screen now shows live router pricing and your real wallet balance, but it does not yet create or submit a real TollGate payment.',
              icon: Icons.construction_rounded,
            ),
            const SizedBox(height: 16),
            if (selectedPrice != null)
              Text(
                'Selected amount: $selectedPrice sats',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (selectedPrice != null) const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(Routes.wallet),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Open Wallet'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentUnavailable(tollgateInfo),
                    icon: const Icon(Icons.bolt),
                    label: const Text('Check Payment'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSelector(TollGateInfo tollgateInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated Access Packages',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _packages.length,
          itemBuilder: (context, index) {
            final package = _packages[index];
            final isSelected = _selectedPackage == index;
            final price = _packagePrice(tollgateInfo, index);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedPackage = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? context.colorScheme.primary.withAlpha(25)
                      : context.colorScheme.surface,
                  border: Border.all(
                    color: isSelected
                        ? context.colorScheme.primary
                        : context.colorScheme.outline.withAlpha(77),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      package.icon,
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      package.label,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      price != null ? '$price sats' : 'Unavailable',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (_selectedPackage == 3) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount in sats',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixText: 'sats',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }
}

class _TimePackage {
  const _TimePackage({
    required this.label,
    required this.minutes,
    required this.icon,
  });

  final String label;
  final int? minutes;
  final IconData icon;
}

class _NetworkSummaryCard extends StatelessWidget {
  const _NetworkSummaryCard({
    required this.ssid,
    required this.tollgateInfo,
  });

  final String ssid;
  final TollGateInfo? tollgateInfo;

  @override
  Widget build(BuildContext context) {
    final priceLabel =
        tollgateInfo?.humanReadablePrice() ?? 'Pricing unavailable';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.wifi,
              color: context.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ssid,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  priceLabel,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (tollgateInfo?.mintUrl.isNotEmpty ?? false) ...[
                  const SizedBox(height: 4),
                  Text(
                    tollgateInfo!.mintUrl,
                    style: context.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({
    required this.walletBalanceAsync,
    required this.selectedPrice,
    required this.hasEnoughBalance,
  });

  final AsyncValue<BigInt> walletBalanceAsync;
  final int? selectedPrice;
  final bool hasEnoughBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Wallet Balance',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          walletBalanceAsync.when(
            data: (balance) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$balance sats',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: selectedPrice == null || hasEnoughBalance
                        ? context.colorScheme.primary
                        : context.colorScheme.error,
                  ),
                ),
                if (selectedPrice != null)
                  Text(
                    hasEnoughBalance
                        ? 'Enough for selection'
                        : 'Need $selectedPrice sats',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: hasEnoughBalance
                          ? context.colorScheme.primary
                          : context.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text(
              error.toString(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
