import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../config/providers/repository_providers.dart';
import '../../../../core/result/result.dart';
import '../../../common/extensions/build_context_x.dart';
import '../../../common/widgets/snackbar/app_snackbar.dart';
import '../../../router/routes.dart';
import '../providers/current_mint_provider.dart';
import '../providers/wallet_balance_stream_provider.dart';
import '../providers/wallet_transactions_provider.dart';

class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  late final TextEditingController _tokenController;
  bool _isReceiving = false;
  BigInt? _receivedAmount;
  String? _receivedMintUrl;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
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

  Future<void> _receiveToken() async {
    final rawInput = _tokenController.text.trim();
    if (rawInput.isEmpty) {
      AppSnackBar.showError(context, message: 'Paste a Cashu token first.');
      return;
    }

    late final Token token;
    try {
      token = Token.parse(encoded: rawInput);
    } catch (_) {
      AppSnackBar.showError(context,
          message: 'That does not look like a valid Cashu token.');
      return;
    }

    setState(() {
      _isReceiving = true;
    });

    final result = await ref.read(walletRepositoryProvider.future).then(
          (repo) => repo.receive(token: token),
        );

    if (!mounted) return;

    switch (result) {
      case Ok(value: final amount):
        await ref
            .read(currentMintProvider.notifier)
            .configureMint(token.mintUrl);
        if (!mounted) return;
        ref.invalidate(walletTransactionsProvider);
        ref.invalidate(walletBalanceStreamProvider);
        setState(() {
          _receivedAmount = amount;
          _receivedMintUrl = token.mintUrl;
          _isReceiving = false;
        });
        AppSnackBar.showSuccess(context,
            message: 'Received ${amount.toString()} sats');
      case Failure(failure: final failure):
        setState(() {
          _isReceiving = false;
        });
        AppSnackBar.showError(context, message: failure.toString());
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
              currentMintAsync.when(
                data: (mint) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Current Mint'),
                    subtitle: Text(mint?.url ??
                        'Will switch to the token mint on receive'),
                  ),
                ),
                error: (error, stackTrace) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('Mint unavailable'),
                    subtitle: Text(error.toString()),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 24),
              if (_receivedAmount != null)
                _ReceiveSuccessCard(
                  amount: _receivedAmount!,
                  mintUrl: _receivedMintUrl ?? 'Unknown mint',
                  onDone: _close,
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paste a Cashu token to receive funds into the wallet.',
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
                                onPressed:
                                    _isReceiving ? null : _pasteFromClipboard,
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
                                label: Text(
                                  _isReceiving ? 'Receiving...' : 'Receive',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
              '${amount.toString()} sats were added from $mintUrl',
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
