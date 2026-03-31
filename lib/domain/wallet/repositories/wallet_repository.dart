import 'package:cdk_flutter/cdk_flutter.dart' hide WalletRepository;

import '../../../core/result/result.dart';
import '../../../core/result/unit.dart';
import '../errors/wallet_errors.dart';
import '../value_objects/mint_amount.dart';
import '../value_objects/mint_url.dart';
import '../value_objects/send_amount.dart';

abstract class WalletRepository {
  Future<Result<Unit, AddMintFailure>> addMint(
    MintUrl mintUrl,
  );

  Future<Result<Unit, RemoveMintFailure>> removeMint(
    MintUrl mintUrl,
  );

  Future<Result<List<Mint>, ListMintsFailure>> listMints();

  Stream<BigInt> getBalanceStream();

  Future<Result<MeltQuote, MeltQuoteFailure>> meltQuote({
    required Mint mint,
    required String request,
  });

  Future<Result<BigInt, MeltFailure>> melt({
    required Mint mint,
    required MeltQuote quote,
  });

  Future<Result<PreparedSend, PrepareSendFailure>> prepareSend({
    required Mint mint,
    required SendAmount amount,
    String? pubkey,
    String? memo,
    bool? includeMemo,
  });

  Future<Result<Token, SendFailure>> send({
    required Mint mint,
    required PreparedSend preparedSend,
  });

  Stream<Result<MintQuote, MintQuoteStreamFailure>> mint({
    required Mint mint,
    required MintAmount amount,
  });
}
