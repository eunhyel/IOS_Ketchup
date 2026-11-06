import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ketchup_flutter/src/features/settings/data/payment_providers.dart';
import 'package:ketchup_flutter/src/features/settings/data/payment_service.dart';
import 'package:ketchup_flutter/src/features/settings/domain/remove_ads_iap_ids.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/remove_ads_subscription_section.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

class _FakeIap implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePayment extends PaymentService {
  _FakePayment(this.fakeIap)
    : super(
        onSubscriptionConfirmed: () async {},
        onSubscriptionRevoked: () async {},
      );

  final _FakeIap fakeIap;
  int attempts = 0;

  @override
  InAppPurchase get iap => fakeIap;

  @override
  Future<bool> purchaseSubscription(ProductDetails product) async {
    attempts++;
    return true;
  }
}

PurchaseDetails _event(String productId, PurchaseStatus status) =>
    PurchaseDetails(
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'google_play',
      ),
      transactionDate: null,
      status: status,
    );

void main() {
  for (final status in [PurchaseStatus.canceled, PurchaseStatus.error]) {
    testWidgets('Play $status without product ID releases purchase button', (
      tester,
    ) async {
      final iap = _FakeIap();
      final payment = _FakePayment(iap);
      addTearDown(iap.updates.close);
      final product = ProductDetails(
        id: RemoveAdsIapIds.subscriptionProductId,
        title: 'Remove ads',
        description: 'Monthly subscription',
        price: '₩1,000',
        rawPrice: 1000,
        currencyCode: 'KRW',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentServiceProvider.overrideWithValue(payment),
            subscriptionStoreProductProvider.overrideWith(
              (ref) async => product,
            ),
            isSubscribedProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(home: RemoveAdsSubscriptionSection()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unrelated purchases and unidentified success must not end this request.
      iap.updates.add([
        _event('another_product', PurchaseStatus.canceled),
        _event('', PurchaseStatus.purchased),
        _event(RemoveAdsIapIds.subscriptionProductId, PurchaseStatus.pending),
      ]);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      iap.updates.add([_event('', status)]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      if (status == PurchaseStatus.error) {
        expect(find.text('결제를 완료하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
      } else {
        expect(find.text('결제를 완료하지 못했습니다. 다시 시도해 주세요.'), findsNothing);
      }
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(payment.attempts, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
