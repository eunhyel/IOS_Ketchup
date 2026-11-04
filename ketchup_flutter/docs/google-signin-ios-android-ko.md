# Google 로그인 문제 해결

기준: 2026-11-04 코드. 아래 항목은 확인 순서이며 특정 오류의 원인을 확정하지 않습니다.

## 공통 점검

1. 앱 시작 시 Firebase 초기화 실패 로그가 있는지 확인합니다.
2. 플랫폼 설정 파일과 앱 식별자가 맞는지 확인합니다.
3. Firebase Authentication의 Google 제공자와 웹 OAuth 클라이언트 설정을 확인합니다.
4. `backup_providers.dart`의 기본 웹 클라이언트 ID 또는 `GOOGLE_WEB_CLIENT_ID` 재정의가 같은 프로젝트를 가리키는지 확인합니다.

현재 코드는 `serverClientId` 기본값을 가지고 있습니다.
빌드 정의나 plist 키가 없다는 이유만으로 웹 클라이언트 ID가 비어 있다고 판단하지 않습니다.

## Android

- 앱 ID는 `com.o2a.ketchup`입니다. iOS ID `com.O2A.Ketchup`과 구분합니다.
- `android/app/google-services.json`이 해당 Android 앱 설정인지 확인합니다.
- 사용하는 서명 인증서가 Firebase/OAuth 설정에 등록되어 있는지 확인합니다.
- 로컬 디버그와 Play 설치에서 결과가 다르면 디버그·릴리스·Play 앱 서명 인증서를 구분해 확인합니다.
- 설정 변경 후에는 해당 앱의 설정 파일을 갱신하고 다시 빌드합니다.

## iOS

- 번들 ID `com.O2A.Ketchup` 및 `ios/Ketchup/GoogleService-Info.plist`를 확인합니다.
- 로그인 복귀 URL Scheme이 해당 OAuth 설정과 맞는지 확인합니다.
- `SceneDelegate` 및 `AppDelegate`의 URL 전달 경로를 확인합니다.
- 기본 웹 클라이언트 ID를 바꿔야 한다면 `GOOGLE_WEB_CLIENT_ID`를 사용합니다.

## 증상별 확인 위치

| 증상 | 확인할 항목 |
|---|---|
| Firebase 초기화 실패 | 플랫폼 설정 파일과 빌드 포함 여부 |
| idToken 없음 | 실제 전달한 웹 클라이언트 ID, Google 인증 결과 |
| 로그인 복귀 후 대기 | iOS URL Scheme, SceneDelegate/AppDelegate 전달 |
| Android 특정 설치본만 실패 | 해당 설치본의 서명 인증서와 앱 ID |
| 로그인 성공, Drive 접근 실패 | Drive API 및 `auth/drive` 권한 확보 |
| 로그인 후 일기가 자동 수신됨 | 현재 Firestore는 로그인 시 활성화되며 레거시 토글과 무관 |

설정 예시는 [Firebase·Drive 설정](firebase-drive-setup.md),
iOS 구현은 [OAuth 복귀 처리](firebase-google-signin-ios.md),
일기 수신 조건은 [동기화 정책](sync-policy.md)을 참고합니다.
