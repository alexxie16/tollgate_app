import 'package:tollgate_app/domain/tollgate/models/tollgate_info.dart';

extension TollgateInfoX on TollGateInfo {
  bool get isDataMetric =>
      ['bytes', 'kilobytes', 'megabytes', 'gigabytes'].contains(
        metric.toLowerCase(),
      );

  double get stepSizeInMegabytes {
    return switch (metric.toLowerCase()) {
      'bytes' => stepSize / (1024 * 1024),
      'kilobytes' => stepSize / 1024,
      'megabytes' => stepSize.toDouble(),
      'gigabytes' => stepSize * 1024,
      _ => stepSize.toDouble(),
    };
  }

  String humanReadableDataAmount({required int steps}) {
    return _formatMegabytes(stepSizeInMegabytes * steps);
  }

  String humanReadablePrice() {
    final metric = this.metric.toLowerCase();
    final stepSize = this.stepSize;
    final pricePerStep = this.pricePerStep;

    // Handle time-based metrics
    if (['milliseconds', 'seconds', 'minutes', 'hours'].contains(metric)) {
      // Convert everything to minutes for display
      double minutes = switch (metric) {
        'milliseconds' => stepSize / (1000 * 60),
        'seconds' => stepSize / 60,
        'minutes' => stepSize.toDouble(),
        'hours' => stepSize * 60,
        _ => stepSize.toDouble(),
      };

      // If less than 1 minute, show in seconds
      if (minutes < 1) {
        final seconds = (minutes * 60).round();
        return '$pricePerStep sats/${seconds}s';
      }

      // If exactly 1 minute
      if (minutes == 1) {
        return '$pricePerStep sats/min';
      }

      // If more than 60 minutes, show in hours
      if (minutes >= 60) {
        final hours = (minutes / 60).toStringAsFixed(1);
        return '$pricePerStep sats/${hours}h';
      }

      // Show in minutes
      return '$pricePerStep sats/${minutes.round()}min';
    }

    // Handle data-based metrics
    if (isDataMetric) {
      return '$pricePerStep sats/${_formatMegabytes(stepSizeInMegabytes)}';
    }

    // Unknown metric type
    return '$pricePerStep sats per $stepSize $metric';
  }

  String _formatMegabytes(double megabytes) {
    if (megabytes < 1) {
      final kilobytes = megabytes * 1024;
      final wholeKilobytes = kilobytes.truncateToDouble() == kilobytes;
      final label = wholeKilobytes
          ? kilobytes.toStringAsFixed(0)
          : kilobytes.toStringAsFixed(1);
      return '${label}KB';
    }

    if (megabytes >= 1024) {
      final gigabytes = megabytes / 1024;
      final wholeGigabytes = gigabytes.truncateToDouble() == gigabytes;
      final label = wholeGigabytes
          ? gigabytes.toStringAsFixed(0)
          : gigabytes.toStringAsFixed(1);
      return '${label}GB';
    }

    final wholeMegabytes = megabytes.truncateToDouble() == megabytes;
    final label = wholeMegabytes
        ? megabytes.toStringAsFixed(0)
        : megabytes.toStringAsFixed(1);
    return '${label}MB';
  }
}
