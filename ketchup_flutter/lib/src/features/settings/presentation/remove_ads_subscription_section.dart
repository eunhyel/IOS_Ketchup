import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/core/widgets/ketchup_ios_close_title_row.dart';
import 'package:ketchup_flutter/src/features/settings/data/payment_providers.dart';
import 'package:ketchup_flutter/src/features/settings/data/payment_service.dart';
import 'package:ketchup_flutter/src/features/settings/domain/remove_ads_iap_ids.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

/// App Store / Play 공통 — `remove_ads_monthly` 구독으로 광고를 끕니다.
///
/// 상품 로드·구매 스트림은 [PaymentService] / [paymentBillingBootstrapProvider]가 담당합니다.
class RemoveAdsSubscriptionSection extends ConsumerStatefulWidget {
  const RemoveAdsSubscriptionSection({super.key});

  @override
  ConsumerState<RemoveAdsSubscriptionSection> createState() =>
      _RemoveAdsSubscriptionSectionState();
}

class _RemoveAdsSubscriptionSectionState
    extends ConsumerState<RemoveAdsSubscriptionSection> {
  StreamSubscription<List<PurchaseDetails>>? _purchaseUiSub;

  bool _buying = false;
  String? _bannerMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _purchaseUiSub = ref
          .read(paymentServiceProvider)
          .iap
          .purchaseStream
          .listen(_onPurchasesForUiState);
    });
  }

  void _onPurchasesForUiState(List<PurchaseDetails> purchases) {
    for (final PurchaseDetails p in purchases) {
      if (p.productID != RemoveAdsIapIds.subscriptionProductId) {
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          if (mounted) {
            setState(() {
              _buying = true;
              _bannerMessage = '결제가 승인 대기 중입니다. (가족 공유·Ask to Buy 등)';
            });
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
        case PurchaseStatus.canceled:
          if (mounted) {
            setState(() {
              _buying = false;
              if (p.status != PurchaseStatus.canceled) {
                _bannerMessage = null;
              }
            });
          }
          break;
        case PurchaseStatus.error:
          if (mounted) {
            setState(() {
              _buying = false;
              _bannerMessage = p.error?.message ?? '결제에 실패했습니다.';
            });
          }
          break;
      }
    }
  }

  @override
  void dispose() {
    unawaited(_purchaseUiSub?.cancel());
    super.dispose();
  }

  Future<void> _buy(ProductDetails? product, PaymentService payment) async {
    if (product == null || _buying) {
      return;
    }
    setState(() {
      _buying = true;
      _bannerMessage = null;
    });
    final bool started = await payment.purchaseSubscription(product);
    if (!mounted) {
      return;
    }
    if (!started) {
      setState(() {
        _buying = false;
        _bannerMessage = '결제 창을 열 수 없습니다.';
      });
    }
  }

  Future<void> _restore(PaymentService payment) async {
    try {
      await payment.restorePurchases();
    } catch (_) {
      if (mounted) {
        setState(() => _bannerMessage = '복원 요청에 실패했습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProductDetails?> productAsync = ref.watch(
      subscriptionStoreProductProvider,
    );
    final PaymentService payment = ref.watch(paymentServiceProvider);
    final bool isSubscribed = ref.watch(isSubscribedProvider);

    final bool loadingStore = productAsync.isLoading;
    final ProductDetails? product = productAsync.valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(KetchupIosAssets.bgPattern),
            repeat: ImageRepeat.repeat,
            fit: BoxFit.none,
            alignment: Alignment.topLeft,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              KetchupIosCloseTitleRow(
                title: '광고 제거',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        '메인 하단 배너와 일기 저장 후\n'
                        '전면 광고를 끕니다.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: ketchupContentWeight(context),
                          color: const Color(0xFF5C5C5C),
                        ),
                      ),
                      if (_bannerMessage != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          _bannerMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade800,
                            fontWeight: ketchupContentWeight(context),
                          ),
                        ),
                      ],
                      if (productAsync.hasError) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          '상품 정보를 불러오지 못했습니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade800,
                            fontWeight: ketchupContentWeight(context),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (isSubscribed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '광고 제거 구독이 적용되었습니다.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: ketchupContentWeight(context),
                                    color: const Color(0xFF303030),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        FilledButton(
                          onPressed:
                              (loadingStore || product == null || _buying)
                              ? null
                              : () => unawaited(_buy(product, payment)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFED5151),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: loadingStore || _buying
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  product == null
                                      ? '상품 정보 없음'
                                      : '광고 제거 구독하기\n${product.title} · ${product.price}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: ketchupContentWeight(context),
                                  ),
                                ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: loadingStore
                            ? null
                            : () => unawaited(_restore(payment)),
                        child: Text(
                          '구매 복원',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: ketchupContentWeight(context),
                            color: const Color(0xFF5C5C5C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
