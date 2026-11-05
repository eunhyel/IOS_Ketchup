# Ketchup Flutter

기존 iOS 케찹 일기 앱의 경험을 Android·iOS로 제공하는 Flutter 프로젝트입니다.
월별 일기, 사진 첨부, 잠금, 글꼴 설정, Google Drive 백업, Firestore 동기화,
PDF 내보내기, 광고 및 광고 제거 구독을 구현합니다.

> 기준: 2026-11-04 저장소 코드, 앱 버전 `1.1.11+19`.
> 구현 현황을 설명하며 실제 기기·스토어·클라우드 운영 검증 완료를 뜻하지 않습니다.

## 개발 환경

- Dart SDK 제약: `^3.11.3` (`pubspec.yaml`). 이를 지원하는 Flutter SDK가 필요합니다.
- Android: compile/target SDK 36, min SDK `max(flutter.minSdkVersion, 23)`, Java 17, NDK `27.0.12077973`.
- iOS: Podfile 기준 16.0 이상, Xcode 프로젝트·워크스페이스·스킴 이름 `Ketchup`.
- 웹·데스크톱 폴더도 있지만 모바일 전용 코드와 플러그인이 있어 지원 검증 대상은 Android·iOS입니다.

## 실행

아래 명령은 `ketchup_flutter` 디렉터리에서 실행합니다.

```bash
flutter pub get
flutter devices
flutter run -d <android-device-id>
flutter run --flavor Ketchup -d <ios-device-id>
```

실행 전 Firebase 플랫폼 설정과 서명 환경을 준비합니다.
Android Gradle은 구성 단계에서 프로젝트 루트 또는 `android/`의 `key.properties`를 요구합니다.
현재 프로젝트의 키스토어 경로와 서명 값을 사용하되 비밀번호나 키 파일을 문서에 넣지 않습니다.
iOS는 `ios/Ketchup.xcworkspace`에서 서명 팀·프로비저닝을 확인합니다.
로그인 설정은 [Firebase·Drive 설정](docs/firebase-drive-setup.md)을 참고합니다.

## 구조와 데이터 흐름

```text
lib/main.dart                  초기화, 잠금·동기화·결제 연결
lib/src/app.dart               테마와 명명 라우트
lib/src/core/                  저장소, 잠금, 광고, 테마, 플랫폼 브리지
lib/src/features/diary/        일기 목록·작성·로컬 저장
lib/src/features/settings/     설정과 구독 결제
lib/src/features/backup/       Google 로그인, Drive 백업·복원, PDF
lib/src/features/sync/         Firestore 동기화
assets/                       기존 iOS 디자인 이미지와 글꼴
ios/Ketchup/SceneDelegate.swift  CloudKit·Realm·공유 네이티브 연동
```

상태 관리는 Riverpod, 로컬 DB는 Isar Community를 사용합니다.
기능은 `presentation`, `data`, 필요 시 `domain`으로 나뉘며 일기는
`DiaryRepository` 인터페이스를 통해 저장합니다.
작성·수정은 로컬 저장과 목록 갱신을 먼저 처리하고 원격 전송을 뒤에서 실행합니다.
비로그인 보관함과 Google 계정별 DB·사진·임시저장을 분리하며 기존 일기는 자동 업로드하지 않습니다.
Drive 파일 백업과 Firestore 동기화는 별개입니다.
iCloud는 비로그인 보관함 전용이며 설정 UI는 iOS debug/profile 빌드에서만 보입니다.

## 검증

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Isar 모델을 변경했을 때 생성 코드를 갱신합니다.

```bash
dart run build_runner build --delete-conflicting-outputs
```

2026-11-04 확인 결과:

- 정적 분석: 오류 0건, 경고 3건, info 6건. 미사용 코드, 비동기 이후 `BuildContext` 접근 등이 남아 있습니다.
- 테스트: 구독 상태·백업 이미지 회귀 테스트 7개 통과. 기존 `test/widget_test.dart`의 화면 테스트 1개는 별도입니다. 실행 중 완료되지 않아 수동 중단했으며 통과 확인은 못 했습니다. 중단 과정의 종료 오류를 기능 실패 원인으로 확정하지 않습니다.
- 이번 확인에서 기기 빌드, 로그인, 결제, 백업·복원의 실제 서비스 검증은 수행하지 않았습니다.

## 개발 시 확인할 사항

- 구독 권한은 스토어에서 시작·복귀·구매/복원 후에만 재조회합니다. 서버 검증·서버 알림은 별도 구현이 필요합니다.
- 작성 화면과 백업 화면이 각각 1,000줄 이상이므로 변경 시 UI와 비동기 데이터 처리를 함께 확인합니다.
- 버전 변경 시 `pubspec.yaml` 외에 설정 화면의 버전 문자열과 백업의 `APP_VERSION` 기본값도 확인합니다.
- 초기화는 원격 일기 삭제도 시도합니다. 정확한 범위는 동기화 정책을 참고합니다.

## 문서

- [기능 명세](docs/feature-spec.md)
- [데이터·백업 스키마](docs/data-schema.md)
- [동기화·초기화 정책](docs/sync-policy.md)
- [Firebase·Drive 설정](docs/firebase-drive-setup.md)
- [Google 로그인 점검](docs/google-signin-ios-android-ko.md)
- [iOS OAuth 복귀 처리](docs/firebase-google-signin-ios.md)
- [iOS 기기 실행 문제 해결](docs/ios-device-troubleshooting-ko.md)
