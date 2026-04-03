import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob 배너 유닛 ID.
///
/// - 디버그: Google 샘플 광고
/// - 릴리스: Android / iOS 각각 프로덕션 배너 ID. `--dart-define=ADMOB_BANNER_ANDROID=...` 등으로 덮어쓸 수 있음.
abstract final class AdConfig {
  static const String _testAndroidBanner =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testIosBanner =
      'ca-app-pub-3940256099942544/2934735716';

  static const String _prodAndroidBanner =
      'ca-app-pub-3637465572249358/1554098357';
  static const String _prodIosBanner =
      'ca-app-pub-3637465572249358/6614853349';

  static String? get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid ? _testAndroidBanner : _testIosBanner;
    }
    const String android = String.fromEnvironment(
      'ADMOB_BANNER_ANDROID',
      defaultValue: _prodAndroidBanner,
    );
    const String ios = String.fromEnvironment(
      'ADMOB_BANNER_IOS',
      defaultValue: _prodIosBanner,
    );
    final String id = Platform.isAndroid ? android : ios;
    if (id.isEmpty) {
      return null;
    }
    return id;
  }
}
