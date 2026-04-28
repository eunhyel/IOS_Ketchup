import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
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

  static const int _maxLoadAttempts = 3;
  static const Duration _retryDelay = Duration(milliseconds: 280);

  static InterstitialAd? _preloaded;
  static String? _preloadedUnitId;
  static bool _preloadInFlight = false;

  /// 동시에 여러 번 [showAfterSave]가 돌면 전면이 겹쳐 뜰 수 있어 1개만 허용합니다.
  static bool _saveFlowShowInProgress = false;

  /// 새 일기 작성 화면에서 호출 — 저장 직후 전면이 이미 로드된 상태일 수 있어 체감 지연이 줄어듭니다.
  static void preloadForSaveFlow() {
    if (!AdConfig.enableInterstitialAds) {
      return;
    }
    if (AdConfig.interstitialAdUnitId == null) {
      return;
    }
    _startPreloadIfNeeded();
  }

  /// 작성 화면을 나갈 때 미사용 프리로드를 정리합니다.
  static void discardPreloadedIfAny() {
    _preloaded?.dispose();
    _preloaded = null;
    _preloadedUnitId = null;
  }

  static void _startPreloadIfNeeded() {
    final String? adUnitId = AdConfig.interstitialAdUnitId;
    if (!_supported || adUnitId == null) {
      return;
    }
    if (_preloaded != null && _preloadedUnitId == adUnitId) {
      return;
    }
    if (_preloadInFlight) {
      return;
    }
    _preloadInFlight = true;
    unawaited(
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd loaded) {
            _preloadInFlight = false;
            _preloaded?.dispose();
            _preloaded = loaded;
            _preloadedUnitId = adUnitId;
          },
          onAdFailedToLoad: (LoadAdError error) {
            _preloadInFlight = false;
            if (kDebugMode) {
              debugPrint(
                'KetchupInterstitial preload failed: ${error.message}',
              );
            }
          },
        ),
      ),
    );
  }

  static InterstitialAd? _takePreloaded(String adUnitId) {
    if (_preloaded != null && _preloadedUnitId == adUnitId) {
      final InterstitialAd ad = _preloaded!;
      _preloaded = null;
      _preloadedUnitId = null;
      return ad;
    }
    return null;
  }

  /// 저장 완료 후 1회 전면 광고를 시도합니다.
  static Future<void> showAfterSave({bool removeAds = false}) async {
    if (_saveFlowShowInProgress) {
      return;
    }
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

    _saveFlowShowInProgress = true;
    try {
      // [main]에서 이미 초기화 — 저장 직후 여기서 await 하면 체감 지연이 커집니다.
      unawaited(MobileAds.instance.initialize());

      final InterstitialAd? warmed = _takePreloaded(adUnitId);
      if (warmed != null) {
        final _InterstitialFlowResult r = await _presentAndWaitDismissed(warmed);
        if (r == _InterstitialFlowResult.dismissed) {
          _startPreloadIfNeeded();
          return;
        }
      }

      // `aborted`(표시 실패 등)마다 재시도하면 전면이 연속으로 여러 번 뜰 수 있음.
      // 재시도는 **로드 실패(loadFailed)** 일 때만 합니다.
      for (int attempt = 1; attempt <= _maxLoadAttempts; attempt++) {
        final _InterstitialFlowResult result = await _loadShowAndWaitDismiss(
          adUnitId: adUnitId,
          attempt: attempt,
        );
        if (result == _InterstitialFlowResult.dismissed) {
          _startPreloadIfNeeded();
          return;
        }
        if (result != _InterstitialFlowResult.loadFailed) {
          break;
        }
        if (attempt < _maxLoadAttempts) {
          developer.log(
            'retry after load failure ($attempt/$_maxLoadAttempts)',
            name: 'KetchupInterstitial',
          );
          await Future<void>.delayed(_retryDelay);
        }
      }
    } finally {
      _saveFlowShowInProgress = false;
    }
  }

  static Future<_InterstitialFlowResult> _presentAndWaitDismissed(
    InterstitialAd loaded,
  ) async {
    final Completer<void> done = Completer<void>();
    var outcome = _InterstitialFlowResult.aborted;

    void safeDone() {
      if (!done.isCompleted) {
        done.complete();
      }
    }

    loaded.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        outcome = _InterstitialFlowResult.dismissed;
        ad.dispose();
        safeDone();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        developer.log(
          'onAdFailedToShow: $error',
          name: 'KetchupInterstitial',
        );
        outcome = _InterstitialFlowResult.aborted;
        ad.dispose();
        safeDone();
      },
    );

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
      loaded.dispose();
      safeDone();
    }

    await done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        developer.log(
          'timeout waiting for dismiss',
          name: 'KetchupInterstitial',
        );
      },
    );

    return outcome;
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
          unawaited(() async {
            outcome = await _presentAndWaitDismissed(loaded);
            safeDone();
          }());
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
