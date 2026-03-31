import 'dart:io';

import 'package:cdk_flutter/cdk_flutter.dart' as cdk;
import 'package:path_provider/path_provider.dart';

class CashuWalletDataSource {
  final cdk.WalletRepository _wallet;

  CashuWalletDataSource._(this._wallet);

  static Future<CashuWalletDataSource> init() async {
    await cdk.CdkFlutter.init();
    final path = await getApplicationDocumentsDirectory();
    final mnemonicFile = File('${path.path}/mnemonic.txt');

    String mnemonic;
    if (await mnemonicFile.exists()) {
      mnemonic = await mnemonicFile.readAsString();
    } else {
      mnemonic = cdk.generateMnemonic();
      await mnemonicFile.writeAsString(mnemonic);
    }

    final db =
        await cdk.WalletDatabase.newInstance(path: '${path.path}/wallet.sqlite');
    final wallet = await cdk.WalletRepository.newInstance(
      unit: 'sat',
      mnemonic: mnemonic,
      db: db,
    );

    return CashuWalletDataSource._(wallet);
  }

  cdk.WalletRepository get wallet => _wallet;
}
