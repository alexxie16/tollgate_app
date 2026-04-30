import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/core/result/result.dart';
import 'package:tollgate_app/presentation/common/extensions/async_value_x.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/common/extensions/tollgate_info_x.dart';
import 'package:tollgate_app/presentation/common/widgets/snackbar/app_snackbar.dart';
import 'package:tollgate_app/presentation/router/routes.dart';

import '../../../../domain/tollgate/constants/tollgate_constants.dart';
import '../../../../domain/tollgate/models/tollgate_info.dart';
import '../../../../domain/tollgate/models/tollgate_payment_response.dart';
import '../interactors/tollgate_interactor.dart';
import '../providers/tollgate_providers.dart';
import '../../wallet/providers/local_ecash_providers.dart';

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
  int _selectedPackage = 0;
  bool _isSubmitting = false;
  String? _sessionAuthToken;
  int? _lastTopUpAmount;
  TollGatePaymentResponse? _lastPaymentResponse;
  final TextEditingController _customAmountController = TextEditingController();

  final List<_DataPackage> _packages = const [
    _DataPackage(stepCount: 1, icon: Icons.sd_storage),
    _DataPackage(stepCount: 5, icon: Icons.storage),
    _DataPackage(stepCount: 10, icon: Icons.cloud_queue),
    _DataPackage(stepCount: null, icon: Icons.edit),
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

  bool _supportsDataMetric(TollGateInfo? tollgateInfo) {
    return tollgateInfo?.isDataMetric ?? false;
  }

  int? _selectedCustomMegabytes() {
    return int.tryParse(_customAmountController.text.trim());
  }

  String? _selectedDataAmountLabel(
      TollGateInfo? tollgateInfo, int packageIndex) {
    if (!_supportsDataMetric(tollgateInfo)) {
      return null;
    }

    if (packageIndex == _packages.length - 1) {
      final megabytes = _selectedCustomMegabytes();
      if (megabytes == null || megabytes <= 0) {
        return null;
      }
      return _formatMegabytes(megabytes.toDouble());
    }

    final stepCount = _packages[packageIndex].stepCount;
    if (stepCount == null) {
      return null;
    }

    return tollgateInfo!.humanReadableDataAmount(steps: stepCount);
  }

  int? _packagePrice(TollGateInfo? tollgateInfo, int packageIndex) {
    if (!_supportsDataMetric(tollgateInfo)) {
      return null;
    }

    if (packageIndex == _packages.length - 1) {
      final megabytes = _selectedCustomMegabytes();
      if (megabytes == null || megabytes <= 0) {
        return null;
      }

      final price = tollgateInfo!.calculatePrice(megabytes: megabytes);
      return price > 0 ? price : null;
    }

    final stepCount = _packages[packageIndex].stepCount;
    if (stepCount == null) {
      return null;
    }

    return tollgateInfo!.pricePerStep * stepCount;
  }

  String _formatMegabytes(double megabytes) {
    if (megabytes >= 1024) {
      final gigabytes = megabytes / 1024;
      final wholeGigabytes = gigabytes.truncateToDouble() == gigabytes;
      final label = wholeGigabytes
          ? gigabytes.toStringAsFixed(0)
          : gigabytes.toStringAsFixed(1);
      return '$label GB';
    }

    final wholeMegabytes = megabytes.truncateToDouble() == megabytes;
    final label = wholeMegabytes
        ? megabytes.toStringAsFixed(0)
        : megabytes.toStringAsFixed(1);
    return '$label MB';
  }

  Future<void> _submitTopUp(
      TollGateInfo? tollgateInfo, int? selectedPrice) async {
    if (_isSubmitting) {
      return;
    }

    if (tollgateInfo == null) {
      AppSnackBar.showError(
        context,
        message: 'Connect to a TollGate network first to load live pricing.',
      );
      return;
    }

    if (selectedPrice == null || selectedPrice <= 0) {
      AppSnackBar.showError(
        context,
        message: 'Choose a valid top-up amount first.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await TollgateInteractor(ref).topUp(
      tollgateInfo: tollgateInfo,
      amountSats: selectedPrice,
      authToken: _sessionAuthToken,
      ssid: widget.networkData?['ssid'] as String?,
      dataLabel: _selectedDataAmountLabel(tollgateInfo, _selectedPackage),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    switch (result) {
      case Ok(value: final value):
        setState(() {
          _sessionAuthToken =
              value.paymentResponse.authToken ?? _sessionAuthToken;
          _lastTopUpAmount = value.amountSats;
          _lastPaymentResponse = value.paymentResponse;
        });
        AppSnackBar.showSuccess(
          context,
          message: 'Submitted ${value.amountSats} sats to the TollGate.',
        );
      case Failure(failure: final failure):
        AppSnackBar.showError(context, message: failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final networkData = widget.networkData ?? <String, dynamic>{};
    final providedTollgateInfo = _extractTollgateInfo(networkData);
    final liveTollgateInfoAsync =
        ref.watch(tollgateInfoProvider(kTollgateRouterIp)).flatten;
    final tollgateInfo =
        liveTollgateInfoAsync.valueOrNull ?? providedTollgateInfo;
    final ssid = networkData['ssid'] as String? ?? 'Unknown Network';
    final selectedDataAmountLabel =
        _selectedDataAmountLabel(tollgateInfo, _selectedPackage);
    final selectedPrice = _packagePrice(tollgateInfo, _selectedPackage);
    final storedSwappedTokensAsync =
        ref.watch(swappedEcashOneSatTokensProvider);
    final storedSwappedBalanceAsync = storedSwappedTokensAsync.whenData(
      (tokens) => tokens.fold<BigInt>(
        BigInt.zero,
        (total, token) => total + token.amount,
      ),
    );
    final storedSwappedBalance =
        storedSwappedBalanceAsync.valueOrNull ?? BigInt.zero;
    final legacySwappedToken =
        ref.watch(legacySwappedEcashLocalTokenStreamProvider).valueOrNull;
    final selectedAmount =
        selectedPrice == null ? null : BigInt.from(selectedPrice);
    final exactMatchLegacyAmount =
        selectedAmount != null && legacySwappedToken?.amount == selectedAmount
            ? selectedAmount
            : null;
    final hasEnoughSwapped = selectedAmount != null &&
        (storedSwappedBalance >= selectedAmount ||
            exactMatchLegacyAmount != null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TollGate Top Up'),
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
            if (liveTollgateInfoAsync.isLoading && tollgateInfo == null)
              const Center(child: CircularProgressIndicator())
            else if (tollgateInfo == null)
              const _InfoCard(
                title: 'Pricing unavailable',
                message:
                    'This screen loads live TollGate pricing from 172.19.217.1:2121 after the device connects to a TollGate Wi-Fi network.',
                icon: Icons.info_outline,
              )
            else if (!_supportsDataMetric(tollgateInfo))
              _InfoCard(
                title: 'Metric not supported yet',
                message:
                    'The connected router bills in ${tollgateInfo.metric}. The app now expects data-based TollGate pricing in bytes, kilobytes, megabytes, or gigabytes.',
                icon: Icons.warning_amber_rounded,
              )
            else
              _buildPackageSelector(tollgateInfo),
            const SizedBox(height: 16),
            _LocalEcashCard(
              storedSwappedBalanceAsync: storedSwappedBalanceAsync,
              exactMatchLegacyAmount: exactMatchLegacyAmount,
              selectedPrice: selectedPrice,
              hasEnoughBalance: hasEnoughSwapped,
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              title: 'Router API',
              message:
                  'Pricing is fetched from 172.19.217.1:2121 and payment submits the raw Cashu token body to POST http://172.19.217.1:2121/.',
              icon: Icons.router_rounded,
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              title: 'Offline payment',
              message:
                  'TollGate top-up only submits already-stored local swapped tokens to 172.19.217.1. It does not prepare, split, or swap tokens during top-up.',
              icon: Icons.offline_bolt_rounded,
            ),
            const SizedBox(height: 16),
            if (selectedPrice != null && selectedDataAmountLabel != null)
              Text(
                'Selected top up: $selectedDataAmountLabel for $selectedPrice sats',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (selectedPrice != null && selectedDataAmountLabel != null)
              const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(Routes.receive),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Receive eCash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ||
                            tollgateInfo == null ||
                            selectedPrice == null ||
                            !hasEnoughSwapped
                        ? null
                        : () => _submitTopUp(tollgateInfo, selectedPrice),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt),
                    label: Text(
                      _isSubmitting
                          ? 'Submitting...'
                          : selectedDataAmountLabel == null
                              ? 'Top Up'
                              : 'Top Up $selectedDataAmountLabel',
                    ),
                  ),
                ),
              ],
            ),
            if (_lastPaymentResponse != null && _lastTopUpAmount != null) ...[
              const SizedBox(height: 16),
              _PaymentStatusCard(
                amountSats: _lastTopUpAmount!,
                paymentResponse: _lastPaymentResponse!,
              ),
            ],
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
          'Estimated Data Packages',
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
            final label = package.stepCount == null
                ? 'Custom'
                : tollgateInfo.humanReadableDataAmount(
                    steps: package.stepCount!);

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
                      label,
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
              hintText: 'Enter amount in megabytes',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixText: 'MB',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }
}

class _DataPackage {
  const _DataPackage({
    required this.stepCount,
    required this.icon,
  });

  final int? stepCount;
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

class _LocalEcashCard extends StatelessWidget {
  const _LocalEcashCard({
    required this.storedSwappedBalanceAsync,
    required this.exactMatchLegacyAmount,
    required this.selectedPrice,
    required this.hasEnoughBalance,
  });

  final AsyncValue<BigInt> storedSwappedBalanceAsync;
  final BigInt? exactMatchLegacyAmount;
  final int? selectedPrice;
  final bool hasEnoughBalance;

  @override
  Widget build(BuildContext context) {
    final storedSwappedBalance = storedSwappedBalanceAsync.valueOrNull;
    final displayedBalance = exactMatchLegacyAmount != null &&
            (storedSwappedBalance == null ||
                exactMatchLegacyAmount! > storedSwappedBalance)
        ? exactMatchLegacyAmount
        : storedSwappedBalance;

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
                Icons.offline_bolt,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Local eCash',
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (displayedBalance == null)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$displayedBalance sats stored offline',
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
                if (exactMatchLegacyAmount != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'An exact stored swapped token matches this top-up.',
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ],
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

class _PaymentStatusCard extends StatelessWidget {
  const _PaymentStatusCard({
    required this.amountSats,
    required this.paymentResponse,
  });

  final int amountSats;
  final TollGatePaymentResponse paymentResponse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last top-up submitted',
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$amountSats sats sent to the TollGate. Status: ${paymentResponse.status}.',
            style: context.textTheme.bodyMedium,
          ),
          if (paymentResponse.authToken != null &&
              paymentResponse.authToken!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Router session token received.',
              style: context.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
