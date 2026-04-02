import 'package:cdk_flutter/cdk_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tollgate_app/config/providers/repository_providers.dart';

import '../../../../core/result/result.dart';
import '../../../../domain/wallet/errors/wallet_errors.dart';
import '../../../../domain/wallet/value_objects/mint_amount.dart';

part 'mint_transactions_providers.g.dart';

@riverpod
Stream<Result<MintQuote, MintQuoteStreamFailure>> mintQuoteStream(
  Ref ref,
  Mint mint,
  MintAmount mintAmount,
) async* {
  final walletRepo = await ref.watch(walletRepositoryProvider.future);
  yield* walletRepo.mint(mint: mint, amount: mintAmount);
}
