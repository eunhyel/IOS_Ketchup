import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS `AppDelegate.isICloudContainerAvailable` / BackUpView `cloudStatus` 와 동일하게
/// iCloud(CloudKit) 계정 사용 가능 여부를 묻습니다.
class IcloudAvailability {
  static const MethodChannel _channel = MethodChannel('com.o2a.ketchup/settings');

  static Future<bool> isAccountAvailable() async {
    if (!Platform.isIOS) {
      return true;
    }
    try {
      final bool? ok = await _channel.invokeMethod<bool>('isICloudAvailable');
      return ok ?? false;
    } catch (e, st) {
      debugPrint('iCloud 가용성 확인 실패: $e\n$st');
      return false;
    }
  }
}
