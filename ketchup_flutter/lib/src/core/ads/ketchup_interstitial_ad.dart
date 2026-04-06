import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ketchup_flutter/src/core/ads/ad_config.dart';

abstract final class KetchupInterstitialAd {
  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 저장 완료 후 1회 전면 광고를 시도합니다.
  /// 로드 실패/타임아웃이어도 흐름을 막지 않기 위해 빠르게 반환합니다.
  static Future<void> showAfterSave() async {
    if (!AdConfig.enableInterstitialAds) {
      return;
    }
    final String? adUnitId = AdConfig.interstitialAdUnitId;
    if (!_supported || adUnitId == null) {
      return;
    }

    final Completer<void> done = Completer<void>();
    InterstitialAd? ad;

    void safeDone() {
      if (!done.isCompleted) {
        done.complete();
      }
    }

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd loaded) {
          ad = loaded;
          loaded.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              safeDone();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              safeDone();
            },
          );
          loaded.show();
        },
        onAdFailedToLoad: (LoadAdError error) {
          safeDone();
        },
      ),
    );

    await done.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        ad?.dispose();
      },
    );
  }
}

