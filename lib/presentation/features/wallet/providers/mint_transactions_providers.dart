import 'dart:async';

import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tollgate_app/config/providers/repository_providers.dart';

import '../../../../core/result/result.dart';
import '../../../../domain/wallet/errors/wallet_errors.dart';
import '../../../../domain/wallet/value_objects/mint_amount.dart';

typedef MintQuoteRequest = ({String mintUrl, BigInt amount});

final mintQuoteRequestProvider = StreamProvider.autoDispose
    .family<Result<MintQuote, MintQuoteStreamFailure>, MintQuoteRequest>(
  (ref, request) async* {
    final walletRepo = await ref.watch(walletRepositoryProvider.future);
    final stream = walletRepo.mint(
      mint: Mint(url: request.mintUrl),
      amount: MintAmount.fromData(request.amount),
    );
    final iterator = StreamIterator(stream);

    try {
      final hasFirstQuote = await iterator.moveNext().timeout(
            const Duration(seconds: 20),
            onTimeout: () => false,
          );

      if (!hasFirstQuote) {
        yield Result.failure(
          MintQuoteStreamFailure.unexpected(
            TimeoutException(
              'Timed out while creating the Lightning invoice.',
            ),
          ),
        );
        return;
      }

      yield iterator.current;

      while (await iterator.moveNext()) {
        yield iterator.current;
      }
    } catch (error, stackTrace) {
      yield Result.failure(
        MintQuoteStreamFailure.unexpected(error, stackTrace: stackTrace),
      );
    } finally {
      await iterator.cancel();
    }
  },
);
