import 'package:flutter_test/flutter_test.dart';
import 'package:ketchup_flutter/src/features/settings/data/payment_service.dart';

void main() {
  test('expiration revokes a previously active subscription', () async {
    bool active = true;
    final service = PaymentService(
      queryEntitlement: () async => false,
      onSubscriptionConfirmed: () async {
        active = true;
      },
      onSubscriptionRevoked: () async {
        active = false;
      },
    );
    await service.refreshEntitlement();
    expect(active, isFalse);
  });
  test('failed or unavailable query preserves paid access', () async {
    for (final query in <Future<bool?> Function()>[
      () async => null,
      () async => throw StateError('offline'),
    ]) {
      int writes = 0;
      final service = PaymentService(
        queryEntitlement: query,
        onSubscriptionConfirmed: () async {
          writes++;
        },
        onSubscriptionRevoked: () async {
          writes++;
        },
      );
      await service.refreshEntitlement();
      expect(writes, 0);
    }
  });
  test('current entitlement restores access', () async {
    bool active = false;
    final service = PaymentService(
      queryEntitlement: () async => true,
      onSubscriptionConfirmed: () async {
        active = true;
      },
      onSubscriptionRevoked: () async {
        active = false;
      },
    );
    await service.refreshEntitlement();
    expect(active, isTrue);
  });
}
