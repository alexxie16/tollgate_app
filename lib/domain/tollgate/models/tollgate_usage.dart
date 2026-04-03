class TollGateUsage {
  const TollGateUsage({
    required this.usedBytes,
    required this.allocatedBytes,
  });

  final BigInt usedBytes;
  final BigInt allocatedBytes;

  BigInt get remainingBytes {
    final remaining = allocatedBytes - usedBytes;
    return remaining > BigInt.zero ? remaining : BigInt.zero;
  }
}
