# Firebase·Google Drive 프로젝트 설정

기준: 2026-11-04 저장소 설정. 운영 콘솔의 실제 활성 상태는 별도로 확인합니다.

## 플랫폼 식별자와 설정 파일

| 플랫폼 | 앱 식별자 | 설정 파일 |
|---|---|---|
| Android | `com.o2a.ketchup` | `android/app/google-services.json` |
| iOS | `com.O2A.Ketchup` | `ios/Ketchup/GoogleService-Info.plist` |

Android는 `android/app/build.gradle.kts`의 `applicationId`, iOS는 Xcode의
`PRODUCT_BUNDLE_IDENTIFIER` 기준입니다. 대소문자가 서로 다릅니다.
Firebase 프로젝트에서 각 앱의 식별자와 설정 파일이 일치하는지 확인합니다.

## Google 로그인

`backup_providers.dart`는 `GoogleSignIn.serverClientId`에 웹 OAuth 클라이언트 ID를 명시합니다.
현재 기본값이 코드에 있으며 다른 환경에서는 `GOOGLE_WEB_CLIENT_ID`로 덮어씁니다.

```bash
flutter run -d <android-device-id> --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>
flutter run --flavor Ketchup -d <ios-device-id> --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>
```

이 값은 Android/iOS용 클라이언트 ID가 아닌 웹 클라이언트 ID입니다.
빌드 정의를 생략해도 현재 코드는 기본값을 사용합니다.
plist의 `SERVER_CLIENT_ID`를 수정하는 것만으로 Dart에서 전달하는 값을 변경할 수 있다고 가정하지 않습니다.

## 외부 설정 확인 항목

- Firebase Authentication의 Google 로그인 제공자.
- Android 앱에 실제 사용하는 서명 인증서 지문 등록: 로컬 디버그, 릴리스, Play 앱 서명 환경을 구분.
- Google Cloud 프로젝트의 Drive API와 OAuth 동의·권한 설정.
- 로그인 요청 스코프는 `email` 및 `https://www.googleapis.com/auth/drive`.
- iOS OAuth 복귀 URL 설정과 `GIDSignIn` 전달 경로.
- Firestore 접근 규칙과 데이터베이스 준비 상태.

Drive 백업은 일반 Drive의 `Ketchup` 폴더를 사용합니다.
백업 파일 구조는 [데이터 스키마](data-schema.md), 자동 동기화 활성 조건은
[동기화 정책](sync-policy.md), 로그인 점검 순서는 [문제 해결](google-signin-ios-android-ko.md)을 참고합니다.
