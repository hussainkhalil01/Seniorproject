import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StripeConfig {
  static String? _secretKey;

  static Future<String> getSecretKey() async {
    if (_secretKey != null) return _secretKey!;
    const fromEnv =
        String.fromEnvironment('STRIPE_SECRET_KEY', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      _secretKey = fromEnv;
      return _secretKey!;
    }
    try {
      final content = await rootBundle.loadString('assets/.env');
      for (final line in content.split('\n')) {
        if (line.startsWith('STRIPE_SECRET_KEY=')) {
          _secretKey = line.substring('STRIPE_SECRET_KEY='.length).trim();
          return _secretKey!;
        }
      }
    } catch (e) {
      debugPrint('Failed to load Stripe key: $e');
    }
    return '';
  }
}
