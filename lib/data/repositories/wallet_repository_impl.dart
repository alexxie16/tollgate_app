import 'package:cdk_flutter/cdk_flutter.dart' hide WalletRepository;

import '../../core/result/result.dart';
import '../../core/result/unit.dart';
import '../../domain/wallet/errors/wallet_errors.dart';
import '../../domain/wallet/repositories/wallet_repository.dart';
import '../../domain/wallet/value_objects/mint_amount.dart';
import '../../domain/wallet/value_objects/mint_url.dart';
import '../../domain/wallet/value_objects/send_amount.dart';
import '../data_sources/cashu_wallet_data_source.dart';

class WalletRepositoryImpl extends WalletRepository {
  final CashuWalletDataSource walletDataSource;

  WalletRepositoryImpl({
    required this.walletDataSource,
  });

  @override
  Stream<BigInt> getBalanceStream() async* {
    yield* walletDataSource.wallet.streamBalance();
  }

  @override
  Future<Result<Unit, AddMintFailure>> addMint(MintUrl mintUrl) async {
    try {
      await walletDataSource.wallet.addMint(mintUrl: mintUrl.value);
      return Result.ok(unit);
    } catch (e) {
      return Result.failure(AddMintFailure.unexpected(e));
    }
  }

  @override
  Future<Result<Unit, RemoveMintFailure>> removeMint(MintUrl mintUrl) async {
    try {
      await walletDataSource.wallet.removeMint(mintUrl: mintUrl.value);
      return Result.ok(unit);
    } catch (e) {
      return Result.failure(RemoveMintFailure.unexpected(e));
    }
  }

  @override
  Future<Result<List<Mint>, ListMintsFailure>> listMints() async {
    try {
      final mints = await walletDataSource.wallet.listMints();
      return Result.ok(mints);
    } catch (e) {
      return Result.failure(ListMintsFailure.unexpected(e));
    }
  }

  @override
  Future<Result<MeltQuote, MeltQuoteFailure>> meltQuote({
    required Mint mint,
    required String request,
  }) async {
    try {
      final mintWallet =
          await walletDataSource.wallet.getWallet(mintUrl: mint.url);
      if (mintWallet == null) {
        return Result.failure(MeltQuoteFailure.mintNotFound(mint.url));
      }
      final meltQuote = await mintWallet.meltQuote(request: request);
      return Result.ok(meltQuote);
    } catch (e) {
      return Result.failure(MeltQuoteFailure.unexpected(e));
    }
  }

  @override
  Future<Result<BigInt, MeltFailure>> melt({
    required Mint mint,
    required MeltQuote quote,
  }) async {
    try {
      final mintWallet =
          await walletDataSource.wallet.getWallet(mintUrl: mint.url);
      if (mintWallet == null) {
        return Result.failure(MeltFailure.mintNotFound(mint.url));
      }

      final melt = await mintWallet.melt(quote: quote);
      return Result.ok(melt);
    } catch (e) {
      return Result.failure(MeltFailure.unexpected(e));
    }
  }

  @override
  Future<Result<PreparedSend, PrepareSendFailure>> prepareSend({
    required Mint mint,
    required SendAmount amount,
    String? pubkey,
    String? memo,
    bool? includeMemo,
  }) async {
    try {
      final mintWallet =
          await walletDataSource.wallet.getWallet(mintUrl: mint.url);
      if (mintWallet == null) {
        return Result.failure(PrepareSendFailure.mintNotFound(mint.url));
      }
      final preparedSend = await mintWallet.prepareSend(
        amount: amount.value,
      );
      return Result.ok(preparedSend);
    } catch (e) {
      return Result.failure(PrepareSendFailure.unexpected(e));
    }
  }

  @override
  Future<Result<Token, SendFailure>> send({
    required Mint mint,
    required PreparedSend preparedSend,
  }) async {
    try {
      final mintWallet =
          await walletDataSource.wallet.getWallet(mintUrl: mint.url);
      if (mintWallet == null) {
        return Result.failure(SendFailure.mintNotFound(mint.url));
      }

      final token = await mintWallet.send(send: preparedSend);
      return Result.ok(token);
    } catch (e) {
      return Result.failure(SendFailure.unexpected(e));
    }
  }

  @override
  Future<Result<BigInt, ReceiveFailure>> receive({
    required Token token,
  }) async {
    try {
      final mintWallet = await walletDataSource.wallet.createOrGetWallet(
        mintUrl: token.mintUrl,
      );
      final receivedAmount = await mintWallet.receive(token: token);
      return Result.ok(receivedAmount);
    } catch (e, stackTrace) {
      return Result.failure(
        ReceiveFailure.unexpected(e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Stream<Result<MintQuote, MintQuoteStreamFailure>> mint({
    required Mint mint,
    required MintAmount amount,
    String? description,
  }) async* {
    try {
      final mintWallet =
          await walletDataSource.wallet.getWallet(mintUrl: mint.url);

      if (mintWallet == null) {
        yield Result.failure(MintQuoteStreamFailure.mintNotFound(mint.url));
        return;
      }

      await for (final quote
          in mintWallet.mint(amount: amount.value, description: description)) {
        yield Result.ok(quote);
      }
    } catch (e, stackTrace) {
      yield Result.failure(
        MintQuoteStreamFailure.unexpected(e, stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<List<Transaction>> listTransactions() async {
    return walletDataSource.wallet.listTransactions();
  }
}
