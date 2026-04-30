import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/providers/repository_providers.dart';
import '../../../config/themes/theme_provider.dart';
import '../../../core/result/result.dart';
import '../../../domain/wallet/constants/wallet_constants.dart';
import '../../common/widgets/snackbar/app_snackbar.dart';
import '../wallet/providers/current_mint_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoPayEnabled = false;
  double _spendingCap = 500; // In sats
  final double _minSpendingCap = 100;
  final double _maxSpendingCap = 1000;
  late final TextEditingController _mintUrlController;
  List<Mint> _configuredMints = const [];
  bool _isLoadingMints = true;
  bool _isSavingMint = false;
  String? _mintLoadError;

  @override
  void initState() {
    super.initState();
    _mintUrlController = TextEditingController(text: kDefaultMintUrl);
    _loadConfiguredMints();
  }

  @override
  void dispose() {
    _mintUrlController.dispose();
    super.dispose();
  }

  void _toggleAutoPay(bool value) {
    setState(() {
      _autoPayEnabled = value;
    });
  }

  Future<void> _loadConfiguredMints() async {
    final walletRepo = await ref.read(walletRepositoryProvider.future);
    final mintsResult = await walletRepo.listMints();

    if (!mounted) return;

    switch (mintsResult) {
      case Ok(value: final mints):
        setState(() {
          _configuredMints = mints;
          _isLoadingMints = false;
          _mintLoadError = null;
        });
      case Failure(failure: final failure):
        setState(() {
          _configuredMints = const [];
          _isLoadingMints = false;
          _mintLoadError = failure.toString();
        });
    }
  }

  Future<void> _configureMint(String mintUrl) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSavingMint = true;
    });

    final result =
        await ref.read(currentMintProvider.notifier).configureMint(mintUrl);
    await _loadConfiguredMints();

    if (!mounted) return;

    switch (result) {
      case Ok(value: final mint):
        _mintUrlController.text = mint.url;
        AppSnackBar.showSuccess(context,
            message: 'Current mint set to ${mint.url}');
      case Failure(failure: final message):
        AppSnackBar.showError(context, message: message);
    }

    setState(() {
      _isSavingMint = false;
    });
  }

  Future<void> _selectMint(String mintUrl) async {
    setState(() {
      _isSavingMint = true;
    });

    final result =
        await ref.read(currentMintProvider.notifier).selectMint(mintUrl);

    if (!mounted) return;

    switch (result) {
      case Ok(value: final mint):
        _mintUrlController.text = mint.url;
        AppSnackBar.showSuccess(context, message: 'Switched to ${mint.url}');
      case Failure(failure: final message):
        AppSnackBar.showError(context, message: message);
    }

    setState(() {
      _isSavingMint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeNotifierProvider);
    final currentMintAsync = ref.watch(currentMintProvider);

    ref.listen(currentMintProvider, (previous, next) {
      if (previous?.valueOrNull?.url != next.valueOrNull?.url) {
        _loadConfiguredMints();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Theme Settings
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme Mode', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    RadioListTile<ThemeMode>(
                      title: Text('System Default',
                          style: theme.textTheme.bodyMedium),
                      value: ThemeMode.system,
                      groupValue: themeMode,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(themeNotifierProvider.notifier)
                              .setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Light', style: theme.textTheme.bodyMedium),
                      value: ThemeMode.light,
                      groupValue: themeMode,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(themeNotifierProvider.notifier)
                              .setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark', style: theme.textTheme.bodyMedium),
                      value: ThemeMode.dark,
                      groupValue: themeMode,
                      activeColor: colorScheme.primary,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(themeNotifierProvider.notifier)
                              .setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Auto-payment settings
            _buildSectionHeader(context, 'Payment Settings'),
            const SizedBox(height: 16),

            // Auto-pay toggle card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Auto-Pay',
                          style: theme.textTheme.titleMedium,
                        ),
                        Switch(
                          value: _autoPayEnabled,
                          onChanged: _toggleAutoPay,
                          activeColor: colorScheme.primary,
                        ),
                      ],
                    ),
                    if (_autoPayEnabled) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Spending Cap',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_minSpendingCap.toInt()}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Expanded(
                            child: Slider(
                              value: _spendingCap,
                              min: _minSpendingCap,
                              max: _maxSpendingCap,
                              divisions: 9,
                              activeColor: colorScheme.primary,
                              onChanged: (value) {
                                setState(() {
                                  _spendingCap = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            '${_maxSpendingCap.toInt()}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Center(
                        child: Text(
                          '${_spendingCap.toInt()} sats per session',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_spendingCap > 500) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.error.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Setting a high spending cap may deplete your wallet quickly.',
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Cashu Mint settings
            _buildSectionHeader(context, 'Cashu Settings'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use one of the built-in mint presets or connect to another Cashu mint to top up the wallet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildCurrentMintSummary(
                      context,
                      currentMintAsync: currentMintAsync,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSavingMint
                                ? null
                                : () => _configureMint(kDefaultMintUrls.first),
                            icon: const Icon(Icons.bolt),
                            label: const Text('Use Minibits'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSavingMint
                                ? null
                                : () => _configureMint(kDefaultMintUrls[1]),
                            icon: const Icon(Icons.bolt),
                            label: const Text('Use Coinos'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mintUrlController,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Mint URL',
                        hintText: 'https://mint.minibits.cash/Bitcoin',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSavingMint
                            ? null
                            : () => _configureMint(_mintUrlController.text),
                        icon: _isSavingMint
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSavingMint ? 'Saving Mint...' : 'Save Mint',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Configured Mints',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildConfiguredMintsList(
                      context,
                      currentMintAsync: currentMintAsync,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMintSummary(
    BuildContext context, {
    required AsyncValue<Mint?> currentMintAsync,
  }) {
    final theme = Theme.of(context);

    return switch (currentMintAsync) {
      AsyncData(value: final mint) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.primary.withAlpha(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Mint',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mint?.url ?? 'No mint selected yet',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      AsyncError(:final error) => Text(
          'Unable to load the current mint: $error',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _buildConfiguredMintsList(
    BuildContext context, {
    required AsyncValue<Mint?> currentMintAsync,
  }) {
    if (_isLoadingMints) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mintLoadError != null) {
      return Text(
        _mintLoadError!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );
    }

    if (_configuredMints.isEmpty) {
      return Text(
        'No mints configured yet. The default Minibits mint will be used first.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final currentMintUrl = currentMintAsync.valueOrNull?.url;
    return Column(
      children: _configuredMints
          .map(
            (mint) => ListTile(
              onTap: _isSavingMint ? null : () => _selectMint(mint.url),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                mint.url == currentMintUrl
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(
                mint.url,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: mint.url == currentMintUrl
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          )
          .toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge,
      ),
    );
  }
}
