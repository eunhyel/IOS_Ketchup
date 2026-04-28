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
import 'package:url_launcher/url_launcher.dart';

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
  static final Uri _removeAdsLegalUri = Uri.parse(
    'https://www.notion.so/330c654b45c8809c860cf9167098141a?source=copy_link',
  );

  /// Apple 표준 라이선스 계약 (App Store 구독 메타데이터용).
  static final Uri _appleStandardEulaUri = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  StreamSubscription<List<PurchaseDetails>>? _purchaseUiSub;

  bool _buying = false;
  String? _bannerMessage;

  /// true: 구독 버튼을 눌렀는데 상품을 쓸 수 없을 때만 실패 문구(빨간 안내 +「상품 정보 없음」) 표시.
  bool _showProductFetchFailureUi = false;

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

  Future<void> _launchLegalUrl(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('링크를 열 수 없습니다.')),
        );
      }
    }
  }

  TextStyle _legalLinkTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: 13.5,
      fontWeight: ketchupContentWeight(context),
      color: const Color(0xFF5C5C5C),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF5C5C5C),
    );
  }

  void _onSubscribePressed({
    required bool loadingStore,
    required bool isSubscribed,
    required AsyncValue<ProductDetails?> productAsync,
    required PaymentService payment,
  }) {
    if (isSubscribed || _buying || loadingStore) {
      return;
    }
    final ProductDetails? product = productAsync.valueOrNull;
    if (product == null || productAsync.hasError) {
      setState(() {
        _showProductFetchFailureUi = true;
        _bannerMessage = null;
      });
      ref.invalidate(subscriptionStoreProductProvider);
      return;
    }
    unawaited(_buy(product, payment));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProductDetails?> productAsync = ref.watch(
      subscriptionStoreProductProvider,
    );
    final PaymentService payment = ref.watch(paymentServiceProvider);
    final bool isSubscribed = ref.watch(isSubscribedProvider);

    ref.listen<AsyncValue<ProductDetails?>>(
      subscriptionStoreProductProvider,
      (AsyncValue<ProductDetails?>? previous, AsyncValue<ProductDetails?> next) {
        if (!mounted) {
          return;
        }
        if (next.valueOrNull != null && _showProductFetchFailureUi) {
          setState(() => _showProductFetchFailureUi = false);
        }
      },
    );

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
                      if (_showProductFetchFailureUi &&
                          (productAsync.hasError || product == null)) ...<Widget>[
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
                          onPressed: (isSubscribed ||
                                  _buying ||
                                  loadingStore ||
                                  (_showProductFetchFailureUi &&
                                      (product == null || productAsync.hasError)))
                              ? null
                              : () => _onSubscribePressed(
                                    loadingStore: loadingStore,
                                    isSubscribed: isSubscribed,
                                    productAsync: productAsync,
                                    payment: payment,
                                  ),
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
                              : _showProductFetchFailureUi &&
                                      (product == null ||
                                          productAsync.hasError)
                                  ? Text(
                                      '상품 정보 없음',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: ketchupContentWeight(
                                          context,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '광고 제거 - ₩1,100/월',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: ketchupContentWeight(
                                          context,
                                        ),
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
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 6,
                    children: <Widget>[
                      TextButton(
                        onPressed: () => unawaited(_launchLegalUrl(_removeAdsLegalUri)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '개인정보 처리방침 및 이용약관',
                          style: _legalLinkTextStyle(context),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: const Color(0xFF5C5C5C).withValues(alpha: 0.55),
                          height: 1,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            unawaited(_launchLegalUrl(_appleStandardEulaUri)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          '이용약관(EULA)',
                          style: _legalLinkTextStyle(context),
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
