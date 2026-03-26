import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ketchup_flutter/src/core/platform/icloud_availability.dart';

final Provider<FirebaseAuth> firebaseAuthProvider =
    Provider<FirebaseAuth>((Ref ref) => FirebaseAuth.instance);

/// Firebase Auth용 **웹 클라이언트 ID**(기본값 내장). 다른 값으로 덮어쓰려면
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=...` 사용.
final Provider<GoogleSignIn> googleSignInProvider = Provider<GoogleSignIn>(
  (Ref ref) {
    const String webClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue:
          '150068919703-l6n8bspvlekht185kf3omcqbeo77r7k8.apps.googleusercontent.com',
    );
    return GoogleSignIn(
      scopes: const <String>[
        'email',
        'https://www.googleapis.com/auth/drive',
      ],
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );
  },
);

/// [Firebase.initializeApp] 실패·스트림 오류 시에도 화면이 막히지 않도록 안전하게 감쌉니다.
final StreamProvider<User?> firebaseUserProvider = StreamProvider<User?>((Ref ref) {
  return _safeAuthStateChanges();
});

Stream<User?> _safeAuthStateChanges() {
  try {
    if (Firebase.apps.isEmpty) {
      return Stream<User?>.value(null);
    }
    return Stream<User?>.multi((StreamController<User?> controller) {
      final StreamSubscription<User?> sub = FirebaseAuth.instance.authStateChanges().listen(
            controller.add,
            onError: (Object e, StackTrace st) {
              debugPrint('Firebase authStateChanges 오류(로그인 없음으로 처리): $e\n$st');
              controller.add(null);
            },
            onDone: controller.close,
          );
      controller.onCancel = () => sub.cancel();
    });
  } catch (e, st) {
    debugPrint('Firebase Auth 사용 불가: $e\n$st');
    return Stream<User?>.value(null);
  }
}

/// iOS: `CKContainer` 계정(네이티브 BackUpView의 `cloudStatus`와 동일 목적).
/// Android: Firestore 동기화는 iCloud가 없으므로 항상 true.
final FutureProvider<bool> icloudAccountAvailableProvider = FutureProvider<bool>(
  (Ref ref) => IcloudAvailability.isAccountAvailable(),
);
