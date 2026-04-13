import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ketchup_flutter/src/core/ads/ad_config.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

/// 메인 등 하단 고정 배너용 AdMob 슬롯 (Android / iOS만).
/// [AdConfig.respectRemoveAdsUserPreference]가 true일 때만 [AppSettings.removeAds]를 반영합니다.
class KetchupBannerAdSlot extends ConsumerWidget {
  const KetchupBannerAdSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AdConfig.respectRemoveAdsUserPreference) {
      final bool removeAds = ref.watch(
        appSettingsProvider.select(
          (AsyncValue<AppSettings> s) => s.valueOrNull?.removeAds ?? false,
        ),
      );
      if (removeAds) {
        return const SizedBox.shrink();
      }
    }
    return const _KetchupBannerAdLoader();
  }
}

class _KetchupBannerAdLoader extends StatefulWidget {
  const _KetchupBannerAdLoader();

  @override
  State<_KetchupBannerAdLoader> createState() => _KetchupBannerAdLoaderState();
}

class _KetchupBannerAdLoaderState extends State<_KetchupBannerAdLoader> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _loadFailed = false;

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    final String? unitId = AdConfig.bannerAdUnitId;
    if (!_supported || unitId == null) {
      return;
    }
    final BannerAd ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _loaded = true);
          }
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
              _loadFailed = true;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported || AdConfig.bannerAdUnitId == null || _loadFailed) {
      return const SizedBox.shrink();
    }
    final BannerAd? ad = _ad;
    if (!_loaded || ad == null) {
      return SizedBox(height: AdSize.banner.height.toDouble());
    }
    return Center(
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
