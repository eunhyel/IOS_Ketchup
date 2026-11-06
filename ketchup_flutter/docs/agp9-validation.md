# Flutter · AGP 9 · Firebase 전환 검증

2026-11-05, 브랜치 `codex/flutter-agp9-firebase`.
검증 작업 폴더는 `/Users/imac/IOS_Ketchup-agp9/ketchup_flutter`입니다.

## 검증 조합

| 구성 | 이전 | 후보 |
|---|---|---|
| Flutter | 3.41.6 | 3.44.9 |
| Dart | 3.11.4 | 3.12.2 |
| AGP | 8.13.1 | 9.0.1 |
| Gradle | 8.14 | 9.1.0 |
| Kotlin Gradle Plugin | 2.2.20 | 2.4.21 |
| NDK | 27.0.12077973 | 28.2.13676358 |
| firebase_core | 3.15.2 | 5.1.0 |
| firebase_auth | 5.7.0 | 7.0.1 |
| cloud_firestore | 5.6.12 | 7.1.0 |
| firebase_analytics | 11.6.0 | 13.0.1 |

현재 플러그인들이 기존 Kotlin Gradle Plugin을 적용하므로
`android.builtInKotlin=false`, `android.newDsl=false` 호환 모드를 사용합니다.
AGP 9 실행은 확인했으며 Built-in Kotlin 및 새 DSL로의 완전한 전환은 남아 있습니다.
Kotlin compilerOptions를 JVM 17로 지정했습니다.
기존 DSL에 대한 사용 중단 진단은 앱 Gradle 파일에서만 억제합니다.

참고한 공식 문서는 [Flutter AGP 9 마이그레이션](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin)과
[AGP 9.0 호환성](https://developer.android.com/build/releases/agp-9-0-0-release-notes)입니다.

## 발견한 문제와 변경

- 화면 전환 빌더의 import가 새 Flutter에서 Cupertino 라이브러리로 이동해 import를 추가했습니다.
- 최신 Analytics의 Kotlin 2.4 메타데이터와 기존 Kotlin 2.2가 충돌해 Kotlin을 갱신했습니다.
- AGP 9의 R8이 WorkManager의 Room 데이터베이스 생성자를 제거해 Android 10에서 앱 시작이 실패했습니다.
  `android/app/proguard-rules.pro`에서 `androidx.work.impl.WorkDatabase_Impl`의 공개 기본 생성자를 보존합니다.
- Android 10 소프트웨어 GPU 에뮬레이터에서 FlutterJNI.nativeSurfaceCreated 대기 ANR을 관찰했습니다.
  같은 빌드는 호스트 GPU에서는 정상 실행됐습니다. 실제 구형 GPU 기기 검증이 필요합니다.
- 새 SDK가 만든 빌드 폴더 안의 타사 소스가 분석 대상에 들어가지 않도록 `build/**`를 분석에서 제외했습니다.

## 확인 결과

- 서명된 릴리스 AAB 빌드 성공. 검증 아티팩트 버전은 CLI 재정의로 `1.1.12 (21)`입니다.
- 정적 분석에서 오류·경고 없음. 기존 info 6건은 유지됩니다.
- 계정 격리, 동기화 중단, 구독 상태, 백업 이미지 회귀 테스트 14개 통과.
- Android 10 에뮬레이터에서 기존 설치 위 업데이트, 앱 시작, 새 일기 저장, 테스트 전면 광고 닫기,
  앱 재실행 후 `migration_smoke_agp9` 본문 유지 확인.
- Android 16 에뮬레이터에서 기존 서명의 설치 위 업데이트, 앱 시작과 기존 일기 표시 확인.
- 최종 실행 확인에서 Android crash 버퍼의 새 치명적 예외 없음.

## R8 및 크기 비교

로컬 R8 mapping.txt의 전체 매핑 클래스 중 원래 이름과 다른 이름으로 매핑된 클래스 비율입니다.
Google Play Console의 최적화·난독화·축소 비율과 계산식이 같다고 가정하지 않습니다.

| 지표 | 기존 빌드 20 | 후보 빌드 21 |
|---|---|---|
| 매핑 클래스 | 14,964 | 10,234 |
| 이름 변경 클래스 | 4,365 (29.2%) | 9,289 (90.8%) |
| AAB 파일 크기 | 66,705,720바이트 | 81,190,910바이트 |

이전 Firebase Auth가 포함한 `-keep class com.google.android.gms.internal.** { *; }` 규칙은 후보의 병합된 R8 설정에서 사라졌습니다.
초기 후보에서 압축된 DEX 합계는 약 4.41MB에서 4.02MB로 줄었습니다.
AAB 증가의 대부분은 새 Flutter가 추가한 libapp 디버그 심볼과 늘어난 매핑 메타데이터입니다.
메타데이터가 포함된 AAB 전체 크기는 실제 기기별 Play 다운로드 크기와 구분해야 합니다.

## 남은 출시 검증

- 실제 Google Play가 있는 기기에서 Google 로그인, Firestore 양방향 동기화, Drive 백업·복원.
- 실제 Android 구독 구매·복원·만료와 Firebase Analytics 수집.
- 구형 실기기의 GPU에서 시작 및 화면 전환.
- iOS의 새 Firebase 의존성으로 CocoaPods 갱신, 배포 빌드와 샌드박스 구독 확인.
- 새 아티팩트에 대한 Google Play Console의 R8 분석 수치 확인.

## 실행 방법

이 작업에서 설치한 별도 SDK는 `/Users/imac/.codex/toolchains/flutter-3.44.9`입니다.

```sh
cd /Users/imac/IOS_Ketchup-agp9/ketchup_flutter
/Users/imac/.codex/toolchains/flutter-3.44.9/bin/flutter pub get
/Users/imac/.codex/toolchains/flutter-3.44.9/bin/flutter analyze --no-pub
/Users/imac/.codex/toolchains/flutter-3.44.9/bin/flutter test --no-pub test/account_storage_test.dart test/sync_isolation_test.dart test/payment_entitlement_test.dart test/backup_images_test.dart
/Users/imac/.codex/toolchains/flutter-3.44.9/bin/flutter build appbundle --release --no-pub --build-name 1.1.12 --build-number 21
```
