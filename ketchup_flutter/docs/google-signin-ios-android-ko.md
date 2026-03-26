# Google 로그인이 iOS/Android에서 안 될 때 (원인 & 해결)

## 왜 iOS에서 특히 안 되나요?

1. **Firebase Auth는 `idToken`이 필요**합니다. `google_sign_in`이 이 토큰을 내려주려면 **OAuth 2.0 클라이언트 유형이 “웹 애플리케이션”인 클라이언트 ID**(웹 클라이언트 ID)를 알아야 합니다.
2. `ios/Ketchup/GoogleService-Info.plist`에 **`SERVER_CLIENT_ID` 키가 없거나**, 빌드 시 **`GOOGLE_WEB_CLIENT_ID`를 넘기지 않으면** `serverClientId`가 비어 있어 **iOS에서 `idToken`이 null**이 되는 경우가 많습니다.  
   (백업 화면에서는 이미 “idToken이 없습니다” 토스트로 안내합니다.)

## iOS 해결 방법 (하나만 하면 됨)

### 방법 A — `GoogleService-Info.plist` (권장)

1. [Firebase Console](https://console.firebase.google.com) → 프로젝트 **ios-ketchup** → **프로젝트 설정(톱니)** → **일반** → **내 앱**
2. **웹(Web)** 앱이 없으면 **앱 추가** → 웹 앱을 만든 뒤, **Google Cloud Console** → **API 및 서비스** → **사용자 인증 정보** → **OAuth 2.0 클라이언트 ID** 중 **유형이 “웹 애플리케이션”** 인 항목의 **클라이언트 ID**를 복사합니다. (형식: `숫자-문자열.apps.googleusercontent.com`)
3. `ios/Ketchup/GoogleService-Info.plist`에 다음을 추가합니다 (값은 위 웹 클라이언트 ID):

```xml
<key>SERVER_CLIENT_ID</key>
<string>여기에_웹_클라이언트_ID.apps.googleusercontent.com</string>
```

4. Xcode에서 **Clean Build Folder** 후 다시 실행합니다.

### 방법 B — 빌드 시 정의

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=여기에_웹_클라이언트_ID.apps.googleusercontent.com
```

Release/Xcode에서도 동일한 `--dart-define`이 들어가도록 스킴/스크립트에 넣어야 합니다.

### 이미 있는 설정 (이 저장소)

- **OAuth 복귀 URL**: `SceneDelegate` / `AppDelegate`에서 `GIDSignIn`에 URL 전달 (먹통 방지) — 이미 적용됨  
- **URL Scheme**: `Info.plist`의 `CFBundleURLSchemes`에 `REVERSED_CLIENT_ID` — 이미 적용됨

---

## Android (시뮬레이터 포함)

1. Firebase Console → **Android 앱** `com.O2A.Ketchup` 선택  
2. **SHA 인증서 지문**에 **디버그 키스토어 SHA-1** 등록 (시뮬레이터/로컬 빌드용):

```bash
# macOS/Linux — 디버그 키스토어 기본 위치
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

3. SHA-1을 등록한 뒤 **`google-services.json`을 다시 내려받아** `android/app/google-services.json`에 덮어씁니다.  
   이때 파일 안의 `oauth_client` 배열이 **비어 있지 않아야** Google 로그인이 정상 동작하는 경우가 많습니다.

4. **웹 클라이언트 ID**는 iOS와 동일하게 `--dart-define=GOOGLE_WEB_CLIENT_ID=...` 를 쓰거나, 필요 시 네이티브 설정을 맞춥니다.

---

## 요약

| 증상 | 흔한 원인 |
|------|-----------|
| 로그인 후 **idToken 없음** (토스트) | 웹 클라이언트 ID 미설정 (`SERVER_CLIENT_ID` / `GOOGLE_WEB_CLIENT_ID`) |
| Android만 실패, `oauth_client: []` | Firebase에 **SHA-1 미등록** → `google-services.json` 재다운로드 |
| iOS에서 **영원히 대기** | OAuth URL 미전달 → 이 프로젝트는 SceneDelegate 처리됨 |
