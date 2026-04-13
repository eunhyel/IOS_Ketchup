import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ketchup_flutter/src/features/settings/data/payment_service.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

/// [PaymentService] 인스턴스 — 구독 확정 시 [AppSettings.removeAds]를 반영합니다.
final Provider<PaymentService> paymentServiceProvider =
    Provider<PaymentService>((Ref ref) {
      final PaymentService service = PaymentService(
        onSubscriptionConfirmed: () =>
            ref.read(appSettingsProvider.notifier).setRemoveAds(true),
      );
      ref.onDispose(service.dispose);
      return service;
    });

/// 앱 기동 시 스토어에서 구독 상품 메타데이터를 불러옵니다.
final FutureProvider<ProductDetails?> subscriptionStoreProductProvider =
    FutureProvider<ProductDetails?>((Ref ref) async {
      final PaymentService service = ref.watch(paymentServiceProvider);
      return service.loadSubscriptionProduct();
    });

/// [PaymentService.startPurchasePipeline] — 구매 스트림 + 복원.
final AsyncNotifierProvider<PaymentBillingBootstrap, void>
paymentBillingBootstrapProvider =
    AsyncNotifierProvider<PaymentBillingBootstrap, void>(
      PaymentBillingBootstrap.new,
    );

class PaymentBillingBootstrap extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    final PaymentService service = ref.read(paymentServiceProvider);
    await service.startPurchasePipeline();
  }
}

/// 앱 트리 상단에서 결제 파이프라인·상품 조회를 활성화합니다.
class PaymentServiceScope extends ConsumerWidget {
  const PaymentServiceScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(paymentBillingBootstrapProvider);
    ref.watch(subscriptionStoreProductProvider);
    return child;
  }
}
