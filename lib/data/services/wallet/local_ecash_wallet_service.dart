import 'dart:io';

import 'package:cdk_flutter/cdk_flutter.dart' as cdk;
import 'package:path_provider/path_provider.dart';

class LocalEcashWalletService {
  // Keep the existing DB filename so older normalized local-eCash data stays recoverable.
  static const _dbName = 'reserve_wallet.sqlite';
  static const _mnemonicName = 'mnemonic.txt';

  Future<cdk.WalletDatabase> _db() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return cdk.WalletDatabase.newInstance(
      path: '${documentsDirectory.path}/$_dbName',
    );
  }

  Future<String> _mnemonic() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final mnemonicFile = File('${documentsDirectory.path}/$_mnemonicName');
    return mnemonicFile.readAsString();
  }

  Future<cdk.WalletRepository> _repository() async {
    await cdk.CdkFlutter.init();
    return cdk.WalletRepository.newInstance(
      unit: 'sat',
      mnemonic: await _mnemonic(),
      db: await _db(),
    );
  }

  Future<cdk.Wallet> walletForMint(String mintUrl) async {
    await cdk.CdkFlutter.init();
    final mnemonic = await _mnemonic();
    final db = await _db();

    return cdk.Wallet(
      mintUrl: mintUrl,
      unit: 'sat',
      mnemonic: mnemonic,
      db: db,
    );
  }

  Future<BigInt> walletBalance(String mintUrl) async {
    final wallet = await walletForMint(mintUrl);
    return wallet.balance();
  }

  Future<void> importTokenAsOneSatProofs({
    required String mintUrl,
    required cdk.Token token,
  }) async {
    final wallet = await walletForMint(mintUrl);
    await wallet.receive(
      token: token,
      opts: cdk.ReceiveOptions(amountSplitTargetValue: BigInt.one),
    );
  }

  Future<cdk.Token> exportToken({
    required String mintUrl,
    required BigInt amount,
  }) async {
    final wallet = await walletForMint(mintUrl);
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

  Future<cdk.Token> swapTokenToOneSatProofs({
    required cdk.Token regularToken,
    cdk.Token? existingSwappedToken,
  }) async {
    final targetMintUrl = regularToken.mintUrl;
    if (existingSwappedToken != null &&
        existingSwappedToken.mintUrl != targetMintUrl) {
      throw Exception(
        'The existing swapped eCash token uses ${existingSwappedToken.mintUrl}, but the regular token uses $targetMintUrl. Mixed-mint swap is not supported yet.',
      );
    }

    final wallet = await walletForMint(targetMintUrl);

    if (existingSwappedToken != null) {
      await wallet.receive(
        token: existingSwappedToken,
        opts: cdk.ReceiveOptions(amountSplitTargetValue: BigInt.one),
      );
    }

    await wallet.receive(
      token: regularToken,
      opts: cdk.ReceiveOptions(amountSplitTargetValue: BigInt.one),
    );

    final totalBalance = await wallet.balance();
    return exportToken(
      mintUrl: targetMintUrl,
      amount: totalBalance,
    );
  }

  Future<List<LocalEcashPendingBalance>> listPendingBalances() async {
    final repository = await _repository();
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
