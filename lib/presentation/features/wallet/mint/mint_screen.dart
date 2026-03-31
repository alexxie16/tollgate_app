import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/presentation/common/extensions/build_context_x.dart';
import 'package:tollgate_app/presentation/router/routes.dart';

import 'controllers/mint_screen_notifier.dart';
import '../providers/current_mint_provider.dart';
import '../widgets/no_mint_configured_view.dart';
import 'widgets/widgets.dart';

class MintScreen extends ConsumerWidget {
  const MintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMintAsync = ref.watch(currentMintProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? context.colorScheme.surface : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.mintScreenTitle,
          style: TextStyle(
            color: context.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(
          color: context.colorScheme.onSurface,
        ),
      ),
      extendBodyBehindAppBar: false,
      body: currentMintAsync.when(
        data: (currentMint) {
          if (currentMint == null) {
            return const NoMintConfiguredView(title: 'Mint unavailable');
          }

          final mintScreenStateAsync = ref.watch(mintScreenNotifierProvider);

          void handleCloseInvoice() {
            ref.read(mintScreenNotifierProvider.notifier).reset();

            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.wallet);
            }
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: switch (mintScreenStateAsync) {
                  AsyncData(:final value) => _buildUI(
                      mintScreenNotifier:
                          ref.read(mintScreenNotifierProvider.notifier),
                      mintScreenState: value,
                      handleCloseInvoice: handleCloseInvoice,
                    ),
                  AsyncError(:final error) => ErrorWidget(error),
                  _ => SizedBox(
                      height: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          AppBar().preferredSize.height -
                          32,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                },
              ),
            ),
          );
        },
        error: (error, stack) => ErrorWidget(error),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildUI({
    required MintScreenNotifier mintScreenNotifier,
    required MintScreenState mintScreenState,
    required void Function() handleCloseInvoice,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        // Display the mint card
        const CurrentMintCard(),
        const SizedBox(height: 24),
        // Display the amount input form or the invoice display
        switch (mintScreenState) {
          MintScreenEditingState() => AmountInputForm(
              mintScreenNotifier: mintScreenNotifier,
              state: mintScreenState,
            ),
          MintScreenInvoiceState() => InvoiceDisplay(
              mint: mintScreenState.mint,
              amount: mintScreenState.mintAmount,
              onClose: handleCloseInvoice,
            ),
        },
      ],
    );
  }
}
