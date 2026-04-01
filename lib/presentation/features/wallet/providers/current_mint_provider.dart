import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../config/providers/repository_providers.dart';
import '../../../../config/providers/service_providers.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/wallet/repositories/wallet_repository.dart'
    as domain;
import '../../../../domain/wallet/constants/wallet_constants.dart';
import '../../../../domain/wallet/value_objects/mint_url.dart';

part 'current_mint_provider.g.dart';

@riverpod
class CurrentMint extends _$CurrentMint {
  @override
  Future<Mint?> build() async {
    final walletRepo = await ref.watch(walletRepositoryProvider.future);
    final cashuLocalPreferences = ref.watch(cashuLocalPreferencesProvider);
    final mintUrl = cashuLocalPreferences.getCurrentMintUrl();
    if (mintUrl != null) {
      final currentMint = await _findMintByUrl(walletRepo, mintUrl);
      if (currentMint != null) {
        return currentMint;
      }

      await cashuLocalPreferences.removeCurrentMintUrl();
    }

    final defaultMint = await _ensureMintAvailable(
      walletRepo,
      MintUrl.fromData(kDefaultMintUrl),
    );
    if (defaultMint == null) {
      return null;
    }

    await cashuLocalPreferences.saveCurrentMintUrl(defaultMint.url);
    return defaultMint;
  }

  Future<Result<Mint, String>> configureMint(String rawMintUrl) async {
    final mintUrlResult = MintUrl.create(rawMintUrl.trim());
    return switch (mintUrlResult) {
      Ok(value: final mintUrl) => await _setCurrentMint(
          mintUrl,
          ensureMintIsConfigured: true,
        ),
      Failure() => Result.failure('Enter a valid mint URL.'),
    };
  }

  Future<Result<Mint, String>> selectMint(String mintUrl) async {
    return _setCurrentMint(
      MintUrl.fromData(mintUrl),
      ensureMintIsConfigured: false,
    );
  }

  Future<Result<Mint, String>> _setCurrentMint(
    MintUrl mintUrl, {
    required bool ensureMintIsConfigured,
  }) async {
    final cashuLocalPreferences = ref.read(cashuLocalPreferencesProvider);
    final walletRepo = await ref.read(walletRepositoryProvider.future);

    final mint = ensureMintIsConfigured
        ? await _ensureMintAvailable(walletRepo, mintUrl)
        : await _findMintByUrl(walletRepo, mintUrl.value);

    if (mint == null) {
      return Result.failure(
        'Could not load that mint. Check the URL and your internet connection.',
      );
    }

    await cashuLocalPreferences.saveCurrentMintUrl(mint.url);
    state = AsyncData(mint);
    return Result.ok(mint);
  }

  Future<Mint?> _ensureMintAvailable(
    domain.WalletRepository walletRepo,
    MintUrl mintUrl,
  ) async {
    final existingMint = await _findMintByUrl(walletRepo, mintUrl.value);
    if (existingMint != null) {
      return existingMint;
    }

    await walletRepo.addMint(mintUrl);
    return _findMintByUrl(walletRepo, mintUrl.value);
  }

  Future<Mint?> _findMintByUrl(
    domain.WalletRepository walletRepo,
    String mintUrl,
  ) async {
    final mintsResult = await walletRepo.listMints();
    return mintsResult.fold(
      onSuccess: (mints) => mints.where((m) => m.url == mintUrl).firstOrNull,
      onFailure: (failure) => null,
    );
  }
}
