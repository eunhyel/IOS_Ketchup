# Google 로그인 · Firebase Auth (iOS)

> **한글 요약(원인·Android 포함):** [google-signin-ios-android-ko.md](./google-signin-ios-android-ko.md)

## 1. OAuth 복귀 URL (먹통 방지)

`UIScene` 을 쓰는 경우 Google 로그인 후 앱으로 돌아올 때 URL 이 **SceneDelegate** 로 옵니다.  
`SceneDelegate.scene(_:openURLContexts:)` 에서 `GIDSignIn` 에 넘기지 않으면 `signIn()` 이 끝나지 않을 수 있습니다.  
(이 저장소 Ketchup 에 이미 반영되어 있습니다.)

## 2. Firebase 로그인용 idToken (웹 클라이언트 ID)

`GoogleAuthProvider.credential` 에 넣을 **idToken** 은, Google Sign-In 이 **웹 클라이언트 ID(server client id)** 를 알 때 발급됩니다.

1. [Firebase Console](https://console.firebase.google.com) → 프로젝트 → **Authentication** → **Sign-in method** → **Google** 활성화  
2. **프로젝트 설정** → **일반** → **내 앱** 에서 **웹(Web)** 앱이 없으면 추가  
3. **Google Cloud Console** → **API 및 서비스** → **사용자 인증 정보** → **OAuth 2.0 클라이언트 ID** 중 **유형이 "웹 애플리케이션"** 인 클라이언트의 ID를 복사  

그다음 아래 중 하나를 적용합니다.

- **방법 A (권장):** Xcode / 빌드 시  
  `--dart-define=GOOGLE_WEB_CLIENT_ID=웹클라이언트ID.apps.googleusercontent.com`
- **방법 B:** `ios/Ketchup/GoogleService-Info.plist` 에 다음 키 추가 (값은 위와 동일한 웹 클라이언트 ID)

```xml
<key>SERVER_CLIENT_ID</key>
<string>여기에_웹_클라이언트_ID.apps.googleusercontent.com</string>
```

`google_sign_in` iOS 네이티브가 이 값을 읽어 idToken을 발급합니다.
