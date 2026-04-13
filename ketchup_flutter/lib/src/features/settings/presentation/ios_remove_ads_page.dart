import 'package:flutter/material.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/remove_ads_subscription_section.dart';

/// 설정 패널 「광고 제거」— App Store / Play 구독으로 배너·저장 후 전면 광고를 끕니다.
class IosRemoveAdsPage extends StatelessWidget {
  const IosRemoveAdsPage({super.key});

  static const String routeName = '/remove-ads';

  @override
  Widget build(BuildContext context) {
    return const RemoveAdsSubscriptionSection();
  }
}
