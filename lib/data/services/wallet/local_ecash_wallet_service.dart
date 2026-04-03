import 'dart:io';

import 'package:cdk_flutter/cdk_flutter.dart' as cdk;
import 'package:path_provider/path_provider.dart';

import 'cdk_init_service.dart';

class LocalEcashWalletService {
  // Keep the existing staging DB filename so older hidden-wallet balances stay recoverable.
  static const _stagingDbName = 'reserve_wallet.sqlite';
  static const _mainMnemonicName = 'mnemonic.txt';
  static const _poolDbName = 'one_sat_pool_wallet.sqlite';
  static const _poolMnemonicName = 'one_sat_pool_mnemonic.txt';

  Future<cdk.WalletDatabase> _db(String dbName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return cdk.WalletDatabase.newInstance(
      path: '${documentsDirectory.path}/$dbName',
    );
  }

  Future<String> _readOrCreateMnemonic(String fileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final mnemonicFile = File('${documentsDirectory.path}/$fileName');
    if (await mnemonicFile.exists()) {
      return mnemonicFile.readAsString();
    }

    final mnemonic = cdk.generateMnemonic();
    await mnemonicFile.writeAsString(mnemonic);
    return mnemonic;
  }

  Future<cdk.WalletRepository> _stagingRepository() async {
    await CdkInitService.ensureInitialized();
    return cdk.WalletRepository.newInstance(
      unit: 'sat',
      mnemonic: await _readOrCreateMnemonic(_mainMnemonicName),
      db: await _db(_stagingDbName),
    );
  }

  Future<cdk.Wallet> _stagingWalletForMint(String mintUrl) async {
    await CdkInitService.ensureInitialized();
    final mnemonic = await _readOrCreateMnemonic(_mainMnemonicName);
    final db = await _db(_stagingDbName);

    return cdk.Wallet(
      mintUrl: mintUrl,
      unit: 'sat',
      mnemonic: mnemonic,
      db: db,
    );
  }

  Future<cdk.Wallet> _poolWalletForMint(String mintUrl) async {
    await CdkInitService.ensureInitialized();
    final mnemonic = await _readOrCreateMnemonic(_poolMnemonicName);
    final db = await _db(_poolDbName);

    return cdk.Wallet(
      mintUrl: mintUrl,
      unit: 'sat',
      mnemonic: mnemonic,
      db: db,
    );
  }

  Future<BigInt> walletBalance(String mintUrl) async {
    final wallet = await _stagingWalletForMint(mintUrl);
    return wallet.balance();
  }

  Future<void> importToken({
    required String mintUrl,
    required cdk.Token token,
  }) async {
    final wallet = await _stagingWalletForMint(mintUrl);
    await wallet.receive(token: token);
  }

  Future<void> importToPool({
    required String mintUrl,
    required cdk.Token token,
  }) async {
    final wallet = await _poolWalletForMint(mintUrl);
    await wallet.receive(token: token);
  }

  Future<cdk.Token> exportToken({
    required String mintUrl,
    required BigInt amount,
  }) async {
    final wallet = await _stagingWalletForMint(mintUrl);
    final preparedSend = await wallet.prepareSend(amount: amount);
    return wallet.send(send: preparedSend);
  }

  Future<cdk.Token> exportFromPool({
    required String mintUrl,
    required BigInt amount,
  }) async {
    final wallet = await _poolWalletForMint(mintUrl);
    final preparedSend = await wallet.prepareSend(amount: amount);
    return wallet.send(send: preparedSend);
  }

  Future<cdk.Token?> recoverPendingToken(String mintUrl) async {
    final balance = await walletBalance(mintUrl);
    if (balance <= BigInt.zero) {
      return null;
    }

    return exportToken(mintUrl: mintUrl, amount: balance);
  }

  Future<void> topUpOneSatPool(String mintUrl, int refillCount) async {
    if (refillCount <= 0) {
      return;
    }

    final sourceWallet = await _stagingWalletForMint(mintUrl);
    final poolWallet = await _poolWalletForMint(mintUrl);
    for (var i = 0; i < refillCount; i++) {
      final prepared = await sourceWallet.prepareSend(amount: BigInt.one);
      final token = await sourceWallet.send(
        send: prepared,
        memo: 'pool refill',
      );
      await poolWallet.receive(token: cdk.Token.parse(encoded: token.encoded));
    }
  }

  Future<void> swapAllToOneSatPool({
    cdk.Token? regularToken,
    cdk.Token? legacySwappedToken,
  }) async {
    if (regularToken != null) {
      await importToken(mintUrl: regularToken.mintUrl, token: regularToken);
    }

    if (legacySwappedToken != null) {
      await importToPool(
        mintUrl: legacySwappedToken.mintUrl,
        token: legacySwappedToken,
      );
    }

    final balances = await listStagingBalances();
    for (final balance in balances) {
      await topUpOneSatPool(balance.mintUrl, balance.amount.toInt());
    }
  }

  Future<LocalEcashPendingBalance?> poolWithAmount(BigInt amount) async {
    final balances = await listPoolBalances();
    final candidates = balances.where((balance) => balance.amount >= amount);
    if (candidates.isEmpty) {
      return null;
    }

    return candidates.first;
  }

  Future<List<LocalEcashPendingBalance>> listStagingBalances() async {
    final repository = await _stagingRepository();
    final wallets = await repository.listWallets();
    final balances = <LocalEcashPendingBalance>[];

    for (final wallet in wallets) {
      final balance = await wallet.balance();
      if (balance > BigInt.zero) {
        balances.add(
          LocalEcashPendingBalance(
            mintUrl: wallet.mintUrl,
            amount: balance,
          ),
        );
      }
    }

    balances.sort((a, b) => a.mintUrl.compareTo(b.mintUrl));
    return balances;
  }

  Future<List<LocalEcashPendingBalance>> listPoolBalances() async {
    await CdkInitService.ensureInitialized();
    final repository = await cdk.WalletRepository.newInstance(
      unit: 'sat',
      mnemonic: await _readOrCreateMnemonic(_poolMnemonicName),
      db: await _db(_poolDbName),
    );
    final wallets = await repository.listWallets();
    final balances = <LocalEcashPendingBalance>[];

    for (final wallet in wallets) {
      final balance = await wallet.balance();
      if (balance > BigInt.zero) {
        balances.add(
          LocalEcashPendingBalance(
            mintUrl: wallet.mintUrl,
            amount: balance,
          ),
        );
      }
    }

    balances.sort((a, b) => a.mintUrl.compareTo(b.mintUrl));
    return balances;
  }
}

class LocalEcashPendingBalance {
  const LocalEcashPendingBalance({
    required this.mintUrl,
    required this.amount,
  });

  final String mintUrl;
  final BigInt amount;
}
