import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ketchup_flutter/src/core/ads/ad_config.dart';

enum _InterstitialFlowResult {
  /// 사용자가 전면을 닫아 정상 종료
  dismissed,

  /// 로드 API 실패 → 재시도 의미 있음
  loadFailed,

  /// 그 외(표시 실패, 타임아웃 등) → 재시도는 보통 무의미
  aborted,
}

abstract final class KetchupInterstitialAd {
  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 작성 화면에서 곧바로 띄울 때 추가 지연 최소화 (필요 시만 짧게)
  static const Duration _androidShowDelay = Duration.zero;

  static const int _maxLoadAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 700);

  /// 저장 완료 후 1회 전면 광고를 시도합니다.
  static Future<void> showAfterSave({bool removeAds = false}) async {
    if (!AdConfig.enableInterstitialAds) {
      return;
    }
    if (AdConfig.applyRemoveAdsToInterstitial && removeAds) {
      if (kDebugMode) {
        debugPrint(
          'KetchupInterstitial: skipped (removeAds=true, applyRemoveAdsToInterstitial=true)',
        );
      }
      return;
    }
    final String? adUnitId = AdConfig.interstitialAdUnitId;
    if (!_supported || adUnitId == null) {
      developer.log(
        'skipped: unsupported or null adUnitId',
        name: 'KetchupInterstitial',
      );
      return;
    }

    await MobileAds.instance.initialize();

    for (int attempt = 1; attempt <= _maxLoadAttempts; attempt++) {
      final _InterstitialFlowResult result = await _loadShowAndWaitDismiss(
        adUnitId: adUnitId,
        attempt: attempt,
      );
      if (result == _InterstitialFlowResult.dismissed) {
        return;
      }
      if (result == _InterstitialFlowResult.loadFailed &&
          attempt < _maxLoadAttempts) {
        developer.log(
          'retry after load failure ($attempt/$_maxLoadAttempts)',
          name: 'KetchupInterstitial',
        );
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  static Future<_InterstitialFlowResult> _loadShowAndWaitDismiss({
    required String adUnitId,
    required int attempt,
  }) async {
    final Completer<void> done = Completer<void>();
    InterstitialAd? ad;
    var outcome = _InterstitialFlowResult.aborted;

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
              outcome = _InterstitialFlowResult.dismissed;
              ad.dispose();
              safeDone();
            },
            onAdFailedToShowFullScreenContent:
                (InterstitialAd ad, AdError error) {
              developer.log(
                'onAdFailedToShow: $error',
                name: 'KetchupInterstitial',
              );
              outcome = _InterstitialFlowResult.aborted;
              ad.dispose();
              safeDone();
            },
          );
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (Platform.isAndroid) {
              await Future<void>.delayed(_androidShowDelay);
            }
            try {
              await loaded.show();
            } catch (e, st) {
              developer.log(
                'show() error: $e',
                name: 'KetchupInterstitial',
                error: e,
                stackTrace: st,
              );
              outcome = _InterstitialFlowResult.aborted;
              safeDone();
            }
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          outcome = _InterstitialFlowResult.loadFailed;
          developer.log(
            'onAdFailedToLoad attempt=$attempt code=${error.code} '
            'domain=${error.domain} message=${error.message}',
            name: 'KetchupInterstitial',
          );
          safeDone();
        },
      ),
    );

    await done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        developer.log(
          'timeout waiting for dismiss',
          name: 'KetchupInterstitial',
        );
        ad?.dispose();
      },
    );

    return outcome;
  }
}
