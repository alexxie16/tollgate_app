import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/providers/repository_providers.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/wallet/value_objects/mint_amount.dart';
import '../../../../domain/wallet/value_objects/send_amount.dart';
import '../../../common/extensions/build_context_x.dart';
import '../../../common/providers/connectivity_stream_provider.dart';
import '../../../common/widgets/snackbar/app_snackbar.dart';
import '../../../router/routes.dart';
import '../mint/widgets/current_mint_card.dart';
import '../mint/widgets/invoice_display.dart';
import '../providers/current_mint_provider.dart';
import '../providers/local_ecash_providers.dart';

enum _ReceiveMode { token, invoice }

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late final TextEditingController _tokenController;
  late final TextEditingController _invoiceAmountController;

  _ReceiveMode _mode = _ReceiveMode.token;
  bool _isReceiving = false;
  bool _isFinalizingInvoice = false;
  bool _showInvoiceAmountError = false;
  BigInt? _receivedAmount;
  String? _receivedMintUrl;
  MintAmount? _activeInvoiceAmount;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _invoiceAmountController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _invoiceAmountController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (!mounted) return;

    final value = clipboardData?.text?.trim();
    if (value == null || value.isEmpty) {
      AppSnackBar.showInfo(context, message: 'Clipboard is empty.');
      return;
    }

    setState(() {
      _tokenController.text = value;
    });
  }

  Future<bool> _ensureSingleStoredTokenAvailable() async {
    final existingRegularToken =
        await ref.read(regularEcashLocalTokenStreamProvider.future);
    if (existingRegularToken == null) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    AppSnackBar.showError(
      context,
      message:
          'Only one regular local eCash token is supported for now. Swap, send, spend, or clear the current regular token before receiving another one.',
    );
    return false;
  }

  Future<Token> _storeRegularToken(Token token) async {
    await ref.read(storeLocalEcashProvider(token.encoded).future);
    return token;
  }

  Future<void> _receiveToken() async {
    final rawInput = _tokenController.text.trim();
    if (rawInput.isEmpty) {
      AppSnackBar.showError(context, message: 'Paste a Cashu token first.');
      return;
    }

    if (!await _ensureSingleStoredTokenAvailable()) {
      return;
    }

    late final Token token;
    try {
      token = Token.parse(encoded: rawInput);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        message: 'That does not look like a valid Cashu token.',
      );
      return;
    }

    setState(() {
      _isReceiving = true;
    });

    try {
      final storedToken = await _storeRegularToken(token);
      if (!mounted) return;

      setState(() {
        _receivedAmount = storedToken.amount;
        _receivedMintUrl = storedToken.mintUrl;
        _isReceiving = false;
      });
      AppSnackBar.showSuccess(
        context,
        message: 'Received ${storedToken.amount} sats as regular local eCash.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isReceiving = false;
      });
      AppSnackBar.showError(
        context,
        message: 'Failed to store the received token locally.\n$error',
      );
    }
  }

  Future<void> _startInvoiceFlow() async {
    final rawAmount = _invoiceAmountController.text.trim();
    final amount = BigInt.tryParse(rawAmount);
    if (amount == null || MintAmount.validate(amount).isFailure) {
      setState(() {
        _showInvoiceAmountError = true;
      });
      return;
    }

    if (!await _ensureSingleStoredTokenAvailable()) {
      return;
    }

    setState(() {
      _showInvoiceAmountError = false;
      _activeInvoiceAmount = MintAmount.fromData(amount);
    });
  }

  Future<void> _finalizeInvoiceIssued(Mint mint, MintAmount mintAmount) async {
    if (_isFinalizingInvoice) {
      return;
    }

    setState(() {
      _isFinalizingInvoice = true;
    });

    try {
      final walletRepo = await ref.read(walletRepositoryProvider.future);
      final prepareSendResult = await walletRepo.prepareSend(
        mint: mint,
        amount: SendAmount.fromData(mintAmount.value),
      );

      late final PreparedSend preparedSend;
      switch (prepareSendResult) {
        case Ok(value: final value):
          preparedSend = value;
        case Failure(failure: final failure):
          throw failure;
      }

      final sendResult = await walletRepo.send(
        mint: mint,
        preparedSend: preparedSend,
      );

      late final Token temporaryToken;
      switch (sendResult) {
        case Ok(value: final value):
          temporaryToken = value;
        case Failure(failure: final failure):
          throw failure;
      }

      final storedToken = await _storeRegularToken(temporaryToken);
      if (!mounted) return;

      setState(() {
        _receivedAmount = storedToken.amount;
        _receivedMintUrl = storedToken.mintUrl;
        _activeInvoiceAmount = null;
        _isFinalizingInvoice = false;
      });
      AppSnackBar.showSuccess(
        context,
        message:
            'Invoice paid and ${storedToken.amount} sats stored as regular local eCash.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isFinalizingInvoice = false;
        _activeInvoiceAmount = null;
      });
      AppSnackBar.showError(
        context,
        message:
            'The invoice was issued, but storing the resulting local eCash failed.\n$error',
      );
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.wallet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regularTokenAsync = ref.watch(regularEcashLocalTokenStreamProvider);
    final swappedBalanceAsync = ref.watch(swappedEcashBalanceProvider);
    final hasInternet =
        ref.watch(connectivityStreamProvider).valueOrNull ?? false;
    final currentMintAsync = ref.watch(currentMintProvider);

    return Scaffold(
      backgroundColor: context.colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Receive',
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: context.colorScheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasInternet)
                _InfoCard(
                  title: 'Offline mode',
                  message:
                      'Stored local eCash still works for Send and TollGate. Creating invoices needs mint connectivity. Swapping regular eCash into swapped eCash also needs internet.',
                  icon: Icons.cloud_off_rounded,
                ),
              if (!hasInternet) const SizedBox(height: 16),
              if (regularTokenAsync.isLoading || swappedBalanceAsync.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.offline_bolt_rounded),
                    title: const Text('Local eCash status'),
                    subtitle: Text(
                      'Regular: ${regularTokenAsync.valueOrNull?.amount ?? BigInt.zero} sats\n'
                      'Swapped: ${swappedBalanceAsync.valueOrNull ?? BigInt.zero} sats',
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              if (_receivedAmount != null)
                _ReceiveSuccessCard(
                  amount: _receivedAmount!,
                  mintUrl: _receivedMintUrl ?? 'Unknown mint',
                  onDone: _close,
                )
              else ...[
                SegmentedButton<_ReceiveMode>(
                  segments: const [
                    ButtonSegment(
                      value: _ReceiveMode.token,
                      icon: Icon(Icons.download_rounded),
                      label: Text('Paste Token'),
                    ),
                    ButtonSegment(
                      value: _ReceiveMode.invoice,
                      icon: Icon(Icons.bolt_rounded),
                      label: Text('Create Invoice'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _mode = selection.first;
                      _activeInvoiceAmount = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                switch (_mode) {
                  _ReceiveMode.token => _buildTokenReceiveCard(),
                  _ReceiveMode.invoice => currentMintAsync.when(
                      data: (mint) {
                        if (mint == null) {
                          return const _InfoCard(
                            title: 'Mint unavailable',
                            message:
                                'Configure a mint in Settings before creating an invoice.',
                            icon: Icons.warning_amber_rounded,
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const CurrentMintCard(),
                            const SizedBox(height: 16),
                            if (_activeInvoiceAmount == null)
                              _buildInvoiceAmountCard(hasInternet: hasInternet)
                            else ...[
                              if (_isFinalizingInvoice)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              InvoiceDisplay(
                                mint: mint,
                                amount: _activeInvoiceAmount!,
                                onClose: () {
                                  setState(() {
                                    _activeInvoiceAmount = null;
                                  });
                                },
                                onIssued: () => _finalizeInvoiceIssued(
                                    mint, _activeInvoiceAmount!),
                              ),
                            ],
                          ],
                        );
                      },
                      error: (error, stackTrace) => _InfoCard(
                        title: 'Mint unavailable',
                        message: error.toString(),
                        icon: Icons.warning_amber_rounded,
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                },
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenReceiveCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste a Cashu token to store it as regular local eCash in the app.',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              maxLines: 8,
              minLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'cashuA...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isReceiving ? null : _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: const Text('Paste'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isReceiving ? null : _receiveToken,
                    icon: _isReceiving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(_isReceiving ? 'Receiving...' : 'Receive'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceAmountCard({required bool hasInternet}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a Lightning invoice. Once it is paid, the app will mint funds into the wallet and store the resulting token as regular local eCash.',
              style: context.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _invoiceAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter amount in sats',
                suffixText: 'sats',
                errorText: _showInvoiceAmountError
                    ? 'Enter a valid amount greater than 0 sats.'
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: hasInternet ? _startInvoiceFlow : null,
              icon: const Icon(Icons.bolt_rounded),
              label: Text(
                hasInternet
                    ? 'Create Invoice'
                    : 'Create Invoice Needs Internet',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiveSuccessCard extends StatelessWidget {
  const _ReceiveSuccessCard({
    required this.amount,
    required this.mintUrl,
    required this.onDone,
  });

  final BigInt amount;
  final String mintUrl;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Receive Successful',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '$amount sats from $mintUrl were stored as the app\'s regular local eCash token.',
              style: context.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  Text(message, style: context.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
