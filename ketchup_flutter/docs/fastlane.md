# Fastlane 빌드와 테스트 배포

명령은 `pubspec.yaml`이 있는 `ketchup_flutter` 디렉터리에서 실행합니다.
Flutter, Fastlane, Xcode, CocoaPods, Android SDK와 JDK가 필요합니다.

## 서명과 업로드 인증

- iOS는 Xcode의 `Ketchup` 스킴과 기존 앱 서명 설정을 사용합니다. App Store 배포용 서명과 프로비저닝을 준비합니다. 별도의 내보내기 설정이 필요하면 `IOS_EXPORT_OPTIONS_PLIST`에 plist의 절대 경로를 지정합니다.
- Android는 기존 Gradle 릴리스 서명과 `key.properties`를 사용합니다. 실제 Play 업로드 키로 서명합니다.
- `ASC_API_KEY_PATH`에 [Fastlane 형식의 App Store Connect API 키 JSON](https://docs.fastlane.tools/app-store-connect-api/#using-fastlane-api-key-json-file) 경로를 지정합니다.
- `PLAY_SERVICE_ACCOUNT_JSON`에 앱의 내부 테스트 트랙에 배포할 권한이 있는 [Google Play 서비스 계정 JSON](https://docs.fastlane.tools/actions/supply/#setup) 경로를 지정합니다.
- 인증 파일은 저장소 밖에 보관합니다.

## 빌드 파일만 생성

```sh
fastlane ios build
fastlane android build
```

빌드 번호를 생략하면 `pubspec.yaml`의 번호를 사용합니다. 출력은 각각 `build/ios/ipa/`의 IPA와 `build/app/outputs/bundle/release/app-release.aab`입니다.

## 빌드 후 테스트 채널에 업로드

```sh
export ASC_API_KEY_PATH=/absolute/path/to/asc-api-key.json
export PLAY_SERVICE_ACCOUNT_JSON=/absolute/path/to/play-service-account.json

fastlane ios beta build_number:19
fastlane android beta build_number:19
```

`19`는 예시입니다. iOS는 해당 버전에서 쓴 적 없는 더 높은 빌드 번호를, Android는 기존 Play 버전 코드보다 높은 번호를 지정합니다. 버전 이름은 `pubspec.yaml`에서 읽습니다.

iOS는 TestFlight에 업로드하고 Apple의 처리 완료까지 기다리지 않습니다. Android는 Google Play의 내부 테스트 트랙에 배포하며, 콘솔에서 내부 테스트 참여자를 관리합니다.
