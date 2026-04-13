/// App Store Connect / Google Play에 등록한 구독 제품 ID와 반드시 일치해야 합니다.
abstract final class RemoveAdsIapIds {
  /// 자동 갱신 구독 제품 ID (iOS·Android 공통).
  static const String subscriptionProductId = 'remove_ads_monthly';

  /// Google Play 전용: 동일 구독의 **기본 요금제 ID** (Play Console → 구독 → 기본 요금제).
  /// 콘솔에 표시된 값과 다르면 첫 번째 요금제로 대체 시도합니다.
  static const String googlePlayBasePlanId = 'monthly';
}
