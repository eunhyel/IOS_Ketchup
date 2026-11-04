# iOS Google 로그인·Firebase Auth 연결

기준: 2026-11-04 코드.

## OAuth 복귀 URL

`UIScene` 경로에서는 `SceneDelegate.scene(_:openURLContexts:)`가 복귀 URL을 처리합니다.
`AppDelegate.application(_:open:options:)`에도 `GIDSignIn.sharedInstance.handle(url)` 경로가 있습니다.
로그인 화면에서 돌아온 뒤 대기한다면 실제 호출 경로와 URL Scheme을 확인합니다.

관련 파일:

- `ios/Ketchup/SceneDelegate.swift`
- `ios/Ketchup/AppDelegate.swift`
- `ios/Ketchup/Info.plist`
- `ios/Ketchup/GoogleService-Info.plist`

## 웹 클라이언트 ID

현재 `lib/src/features/backup/presentation/backup_providers.dart`는 웹 클라이언트 ID의
기본값을 보유하고 이를 `serverClientId`로 전달합니다.
`GOOGLE_WEB_CLIENT_ID` 빌드 정의로 변경할 수 있습니다.
‘plist에 SERVER_CLIENT_ID가 없으면 항상 serverClientId가 비어 있다’는 과거 설명은 현재 코드에 적용되지 않습니다.

```bash
flutter run --flavor Ketchup -d <ios-device-id> --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>
```

Firebase Auth 로그인 자격 증명에는 Google 인증 결과의 토큰을 사용합니다.
실패 시 Firebase 제공자 설정, 플랫폼 설정 파일, 실제 전달된 웹 클라이언트 ID,
OAuth 복귀 경로를 함께 점검합니다. 토큰 원문은 로그나 문서에 남기지 않습니다.

공통 설정은 [Firebase·Drive 설정](firebase-drive-setup.md), 증상별 점검은
[Google 로그인 문제 해결](google-signin-ios-android-ko.md)을 참고합니다.
