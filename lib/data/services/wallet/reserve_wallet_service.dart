import 'dart:io';

import 'package:cdk_flutter/cdk_flutter.dart' as cdk;
import 'package:path_provider/path_provider.dart';

class ReserveWalletService {
  static const _dbName = 'reserve_wallet.sqlite';
  static const _mnemonicName = 'mnemonic.txt';

  Future<cdk.Wallet> walletForMint(String mintUrl) async {
    await cdk.CdkFlutter.init();
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final mnemonicFile = File('${documentsDirectory.path}/$_mnemonicName');
    final mnemonic = await mnemonicFile.readAsString();
    final db = await cdk.WalletDatabase.newInstance(
      path: '${documentsDirectory.path}/$_dbName',
    );

    return cdk.Wallet(
      mintUrl: mintUrl,
      unit: 'sat',
      mnemonic: mnemonic,
      db: db,
    );
  }

  Future<BigInt> reserveBalance(String mintUrl) async {
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

  Future<cdk.Token> exportReservedToken({
    required String mintUrl,
    required BigInt amount,
  }) async {
    final wallet = await walletForMint(mintUrl);
    final preparedSend = await wallet.prepareSend(amount: amount);
    return wallet.send(send: preparedSend);
  }
}
