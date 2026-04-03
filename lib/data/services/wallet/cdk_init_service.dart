import 'package:cdk_flutter/cdk_flutter.dart' as cdk;

class CdkInitService {
  static Future<void>? _initFuture;

  static Future<void> ensureInitialized() {
    final existingFuture = _initFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final future = cdk.CdkFlutter.init();
    _initFuture = future.then<void>(
      (_) {},
      onError: (error, stackTrace) {
        _initFuture = null;
        throw error;
      },
    );

    return _initFuture!;
  }
}
