import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';

class GritWakelock {
  GritWakelock._();

  static Future<void> enable() async {
    try {
      if (!kIsWeb) {
        await WakelockPlus.enable();
      }
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to enable wakelock: $e');
    }
  }

  static Future<void> disable() async {
    try {
      if (!kIsWeb) {
        await WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('GRIT ERROR: Failed to disable wakelock: $e');
    }
  }
}
