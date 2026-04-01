import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';

import '../../../../../config/themes/colors.dart';
import '../../../../../core/result/result.dart';
import '../../../../../domain/wallet/value_objects/mint_amount.dart';
import '../../../../common/widgets/buttons/app_button.dart';
import '../../../../common/widgets/cards/error_card.dart';
import '../../../../common/widgets/qr_code/qr_code_card.dart';
import '../../../../common/widgets/snackbar/app_snackbar.dart';
import '../../providers/mint_transactions_providers.dart';
import '../../providers/wallet_transactions_provider.dart';

class InvoiceDisplay extends ConsumerWidget {
  final Mint mint;
  final MintAmount amount;
  final VoidCallback onClose;

  const InvoiceDisplay({
    super.key,
    required this.mint,
    required this.amount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mintQuoteProvider = mintQuoteStreamProvider(mint, amount);
    final mintQuoteAsync = ref.watch(mintQuoteProvider);

    ref.listen(mintQuoteProvider, (previous, current) {
      switch (current) {
        case AsyncData(value: Ok(value: final mintQuote)):
          final previousQuote = switch (previous) {
            AsyncData(value: Ok(value: final quote)) => quote,
            _ => null,
          };

          if (mintQuote.state == MintQuoteState.issued &&
              previousQuote?.state != MintQuoteState.issued) {
            ref.invalidate(walletTransactionsProvider);
            Future.delayed(const Duration(seconds: 1), onClose);
          }
        default:
          return;
      }
    });

    return switch (mintQuoteAsync) {
      AsyncData(value: final result) => switch (result) {
          Ok(value: final mintQuote) =>
            _buildWidget(context, mintQuote: mintQuote),
          Failure(failure: final failure) => ErrorCard(
              message: 'Unable to create an invoice.',
              details: failure.toString(),
              onRetry: () => ref.invalidate(mintQuoteProvider),
            ),
        },
      AsyncError(:final error) => ErrorCard(
          message: 'Unable to create an invoice.',
          details: error.toString(),
          onRetry: () => ref.invalidate(mintQuoteProvider),
        ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      _ => const SizedBox(),
    };
  }

  Widget _buildWidget(
    BuildContext context, {
    required MintQuote mintQuote,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDarkMode
          ? context.colorScheme.primary.withAlpha(25)
          : const Color(0xFFFAFAFA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: context.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Invoice Details',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            // Amount display
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: AppColors.actionColors['receive'],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${amount.value} sats',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.actionColors['receive'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // QR Code card
            QrCodeCard(
              data: mintQuote.request,
              size: MediaQuery.of(context).size.width - 82,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(24),
              boxShadow: null,
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: AppButton(
                      label: context.l10n.mintScreenCopyInvoice,
                      onPressed: () => _copyInvoiceToClipboard(
                        context,
                        mintQuote.request,
                      ),
                      icon: Icons.copy,
                      variant: AppButtonVariant.primary,
                      fullWidth: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 56,
                  child: AppButton(
                    label: context.l10n.mintScreenClose,
                    onPressed: onClose,
                    icon: Icons.close,
                    variant: AppButtonVariant.secondary,
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyInvoiceToClipboard(BuildContext context, String invoice) {
    Clipboard.setData(ClipboardData(text: invoice));
    AppSnackBar.showInfo(context,
        message: context.l10n.mintScreenInvoiceCopied);
  }
}
