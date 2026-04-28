import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:ketchup_flutter/src/features/settings/domain/remove_ads_iap_ids.dart';

/// App Store / Google Play 구독 결제를 한곳에서 다룹니다.
///
/// [in_app_purchase] 플러그인 위에 스토어 연결, 상품 조회, 구매 시작, 구매 스트림 처리를 둡니다.
class PaymentService {
  PaymentService({required this.onSubscriptionConfirmed})
    : subscriptionProductId = RemoveAdsIapIds.subscriptionProductId;

  /// App Store Connect / Play Console에 등록한 자동 갱신 구독 제품 ID와 동일해야 합니다.
  final String subscriptionProductId;

  /// 구매가 확정되어 광고 제거(구독) 상태로 올릴 때 호출합니다.
  final Future<void> Function() onSubscriptionConfirmed;

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _started = false;
  int _streamAttachRetry = 0;

  InAppPurchase get iap => _iap;

  /// 스토어(Billing / StoreKit) 사용 가능 여부.
  Future<bool> isAvailable() => _iap.isAvailable();

  /// 구독 상품 1건의 [ProductDetails](가격·제목 등)를 가져옵니다.
  Future<ProductDetails?> loadSubscriptionProduct() async {
    try {
      final bool available = await _waitUntilStoreAvailable();
      if (!available) {
        debugPrint(
          'PaymentService(iOS/Android): InAppPurchase.isAvailable() == false — '
          '기기 제한·스토어 비가용·(iOS) 시뮬레이터 설정 등을 확인하세요.',
        );
        return null;
      }

      final ProductDetailsResponse response = await _iap.queryProductDetails(
        <String>{subscriptionProductId},
      );
      print('NotFound IDs: ${response.notFoundIDs}');

      if (response.error != null) {
        final IAPError err = response.error!;
        debugPrint(
          'PaymentService queryProductDetails error: code=${err.code} '
          'message=${err.message} source=${err.source} details=${err.details}',
        );
        return null;
      }

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'PaymentService: App Store / Play가 다음 ID를 찾지 못함: ${response.notFoundIDs}. '
          '앱 코드의 제품 ID("$subscriptionProductId")와 콘솔 등록이 **완전히 동일**한지, '
          'iOS는 App Store Connect에 **자동 갱신 구독**으로 생성됐는지 확인하세요.',
        );
        return null;
      }

      if (response.productDetails.isEmpty) {
        debugPrint(
          'PaymentService: productDetails 비어 있음 — '
          'iOS: 유료 앱 계약·은행/세무, 구독 "판매 준비 완료", 번들 ID 일치, '
          '샌드박스 계정(설정 → App Store), 제품 전파 지연(수십 분)을 확인하세요.',
        );
        return null;
      }

      if (Platform.isAndroid) {
        return _pickGooglePlaySubscriptionProduct(response.productDetails);
      }
      try {
        return response.productDetails.firstWhere(
          (ProductDetails p) => p.id == subscriptionProductId,
        );
      } on StateError {
        return response.productDetails.first;
      }
    } on Object catch (e, st) {
      debugPrint('PaymentService.loadSubscriptionProduct 예외: $e\n$st');
      return null;
    }
  }

  /// 스토어 연결 상태가 늦게 올라오는 기기에서 초기 조회 실패를 줄이기 위해 짧게 재시도합니다.
  Future<bool> _waitUntilStoreAvailable({
    int attempts = 5,
    Duration delay = const Duration(milliseconds: 700),
  }) async {
    for (int i = 0; i < attempts; i++) {
      try {
        if (await _iap.isAvailable()) {
          return true;
        }
      } on PlatformException catch (e, st) {
        // iOS cold-start에서 StoreKit 채널이 늦게 붙으면 channel-error가 발생할 수 있습니다.
        debugPrint(
          'PaymentService.isAvailable PlatformException: code=${e.code} message=${e.message}\n$st',
        );
      } on Object catch (e, st) {
        debugPrint('PaymentService.isAvailable 예외: $e\n$st');
      }
      if (i < attempts - 1) {
        await Future<void>.delayed(delay);
      }
    }
    return false;
  }

  /// 구매 스트림을 구독하고, 필요 시 [restorePurchases]로 기존 구독을 동기화합니다.
  Future<void> startPurchasePipeline() async {
    if (_started) {
      return;
    }
    if (!await _waitUntilStoreAvailable()) {
      return;
    }
    _started = true;
    _attachPurchaseStream();
    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      debugPrint('PaymentService.restorePurchases: $e $st');
    }
  }

  void _attachPurchaseStream() {
    _purchaseSub?.cancel();
    runZonedGuarded(
      () {
        _purchaseSub = _iap.purchaseStream.listen(
          _onPurchaseUpdates,
          onError: _onPurchaseStreamError,
          cancelOnError: false,
        );
      },
      _onPurchaseStreamError,
    );
  }

  void _onPurchaseStreamError(Object error, StackTrace stackTrace) {
    debugPrint('PaymentService.purchaseStream error: $error\n$stackTrace');
    if (!Platform.isIOS) {
      return;
    }
    if (error is! PlatformException || error.code != 'channel-error') {
      return;
    }
    if (_streamAttachRetry >= 5) {
      debugPrint(
        'PaymentService(iOS): StoreKit channel-error 재시도 한도 초과. '
        'flutter clean / pod install 후 재실행 필요',
      );
      return;
    }
    _streamAttachRetry += 1;
    final int retry = _streamAttachRetry;
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!_started) {
        return;
      }
      debugPrint('PaymentService(iOS): purchaseStream 재연결 시도 #$retry');
      _attachPurchaseStream();
    });
  }

  void dispose() {
    unawaited(_purchaseSub?.cancel());
    _purchaseSub = null;
    _started = false;
  }

  /// 구독 결제 화면을 띄웁니다. Android는 [GooglePlayPurchaseParam]으로 오퍼 토큰이 전달됩니다.
  Future<bool> purchaseSubscription(ProductDetails product) async {
    if (product.id != subscriptionProductId) {
      return false;
    }
    final PurchaseParam param =
        Platform.isAndroid && product is GooglePlayProductDetails
        ? GooglePlayPurchaseParam(productDetails: product)
        : PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    _streamAttachRetry = 0;
    for (final PurchaseDetails purchase in purchases) {
      if (purchase.productID != subscriptionProductId) {
        continue;
      }
      await _handleOnePurchase(purchase);
    }
  }

  Future<void> _handleOnePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      /// iOS: Ask to Buy·심사 대기 등으로 결제가 아직 확정되지 않은 상태.
      case PurchaseStatus.pending:
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // --- 영수증 검증 (서버 권장) ---
        // Apple: App Store Server API / `verificationData.serverVerificationData`(레거시 영수증)
        // Google: Play Developer API + purchase token
        // final String data = purchase.verificationData.serverVerificationData;
        // if (!await MyBackend.verifySubscription(platform: purchase.verificationData.source, payload: data)) {
        //   return;
        // }
        await onSubscriptionConfirmed();
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
      case PurchaseStatus.error:
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        break;
      case PurchaseStatus.canceled:
        break;
    }
  }
}

/// Play에서 여러 베이스 플랜/오퍼가 있을 때 [RemoveAdsIapIds.googlePlayBasePlanId]에 맞는 항목을 고릅니다.
GooglePlayProductDetails? _pickGooglePlaySubscriptionProduct(
  List<ProductDetails> products,
) {
  if (products.isEmpty) {
    return null;
  }
  final String wantPlan = RemoveAdsIapIds.googlePlayBasePlanId;
  GooglePlayProductDetails? anyMatchingProductId;
  for (final ProductDetails p in products) {
    if (p is! GooglePlayProductDetails) {
      continue;
    }
    if (p.id != RemoveAdsIapIds.subscriptionProductId) {
      continue;
    }
    anyMatchingProductId ??= p;
    final int? idx = p.subscriptionIndex;
    if (idx == null) {
      continue;
    }
    final details = p.productDetails.subscriptionOfferDetails;
    if (details == null || idx >= details.length) {
      continue;
    }
    if (wantPlan.isEmpty || details[idx].basePlanId == wantPlan) {
      return p;
    }
  }
  return anyMatchingProductId;
}
