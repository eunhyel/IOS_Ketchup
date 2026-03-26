# Firebase / Google Drive 설정 (Android)

## 1) Firebase 콘솔
1. [Firebase Console](https://console.firebase.google.com/)에서 프로젝트 `ios-ketchup`(또는 동일 프로젝트) 선택
2. **Android 앱 추가** — 패키지 이름: `com.O2A.Ketchup`
3. **google-services.json** 을 내려받아 `android/app/google-services.json` 으로 교체 권장  
   (저장소에 넣은 파일은 플레이스홀더용일 수 있음. 실제 배포 전 반드시 콘솔 파일로 교체)

## 2) Google 로그인 (idToken)
- Android에서 Firebase Auth에 **idToken**을 쓰려면 Firebase에 등록한 **웹 클라이언트 ID**(OAuth 2.0)가 필요합니다.
- 빌드/실행 시:
  ```bash
  flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
  ```
- 웹 클라이언트 ID는 Firebase 콘솔 → 프로젝트 설정 → 일반 → 내 앱 → 웹 앱 또는 Google Cloud Console의 OAuth 클라이언트에서 확인

## 3) Drive API
- Google Cloud Console에서 **Google Drive API** 사용 설정
- 로그인 시 요청 스코프: `https://www.googleapis.com/auth/drive`

## 4) iOS
- `ios/Ketchup/GoogleService-Info.plist` 는 기존 iOS 앱 것을 복사해 두었습니다.
- 번들 ID: `com.O2A.Ketchup` (Xcode 프로젝트와 일치)
