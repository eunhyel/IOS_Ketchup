# Ketchup Flutter 기능 명세

기준: 2026-11-04 코드, `1.1.11+19`. 초기 MVP 계획이 아닌 현재 구현을 기록합니다.
실제 서비스 검증 상태는 [README](../README.md)의 검증 항목을 참고합니다.

## 일기

- 월별 그리드 목록과 이전·다음 월 탐색, 빈 상태 안내.
- 작성·상세 보기·수정 모드, 본문·날짜·기본 이미지 또는 갤러리 사진.
- 저장·삭제 후 목록 갱신, 변경사항이 있는 화면을 닫을 때 확인.
- 신규 작성 임시 저장과 복원, 인스타그램 스토리 공유.
- Isar에 일기 데이터를 저장하고 이미지 파일은 Documents 아래에서 관리.

관련 코드: `lib/src/features/diary/`, `lib/src/core/share/`.

## 설정과 잠금

- 비밀번호 설정과 앱 진입 잠금, 번들 글꼴 선택.
- 개발자 한마디, 케찹의 역사 링크, 앱 버전 표시.
- 설정은 Isar에 저장하고 비밀번호 SHA-256 해시는 별도 JSON 파일에 저장.
- 잠금 UI는 DB 파일 암호화 기능을 의미하지 않습니다.

관련 코드: `lib/src/features/settings/`, `lib/src/core/lock/`.

## 백업·복원과 내보내기

- Google 로그인 및 이전 로그인 복원, Drive 권한 확보.
- Drive의 `Ketchup` 폴더에 `ketchup_backup.zip`을 생성하거나 갱신.
- ZIP에는 Isar 스냅샷, 매니페스트, 존재하는 경우 이미지 번들을 포함.
- 복원 전 덮어쓰기 확인. ZIP → 분리형 v2 → `default.realm` → v1 JSON 순으로 호환 경로 시도.
- iOS 구형 Realm 파싱은 네이티브 브리지 사용. Android는 구형 Realm만 있는 백업을 직접 복원하지 못함.
- 복원 시 현재 선택한 글꼴 유지, 이미지 경로 보정.
- 일기 PDF 내보내기 및 데이터 초기화 제공.

세부 형식과 제한: [데이터 스키마](data-schema.md).

## 동기화

| 경로 | 현재 동작 |
|---|---|
| Firestore | 보관함 UID와 로그인 UID가 일치하고 초기화 차단이 없을 때 활성화 |
| iCloud | 비로그인 보관함의 iOS에서 `useIcloudSync`가 켜진 경우 |
| iCloud 설정 UI | iOS debug/profile에서만 표시, release에서는 숨김 |
| Drive | 사용자가 실행하는 파일 백업·복원. 실시간 동기화와 별개 |

iCloud는 Firestore와 같은 실시간 양방향 리스너가 아닙니다.
로컬이 비어 있을 때 가져오기, 활성화 시 로컬 전체 업로드 등의 경로를 사용합니다.
초기화는 로컬뿐 아니라 iCloud 및 로그인 계정의 Firestore 일기 삭제도 시도합니다.
자세한 조건과 실패 처리는 [동기화 정책](sync-policy.md)을 참고합니다.

## 광고와 구독

- AdMob 배너·전면 광고, 스토어 구독 상품 조회·구매·복원.
- 제품 ID `remove_ads_monthly`, Google Play 기본 요금제 ID `monthly`.
- 광고 제거 여부는 `removeAdsSubscriptionActive`를 기준으로 판단.
- 앱 시작·복귀·구매/복원 후에만 스토어 권한을 조회하여 활성 상태를 갱신.
- iOS는 검증된 StoreKit currentEntitlements, Android는 현재 보유 구매 조회 사용. 만료·회수로 권한이 없으면 광고 제거 해제. 조회 오류 시 기존 상태 유지.
- 서버 영수증 검증 및 서버 알림은 미구현. 실제 스토어 만료·환불 시나리오는 기기 검증 필요.

관련 코드: `lib/src/core/ads/`, `lib/src/features/settings/data/payment_service.dart`.

## 계정별 보관함

비로그인 데이터는 기기에 별도로 유지하며 로그인 계정으로 자동 업로드하지 않습니다. Google 계정마다 DB·사진·임시저장·설정 파일을 분리합니다. 로그아웃하면 비로그인 보관함으로 돌아갑니다.

## 아키텍처

- Riverpod 상태 관리, Isar Community 로컬 DB.
- 기능별 `presentation` / `data` / `domain` 분리.
- `DiaryRepository`와 `SettingsRepository` 인터페이스 및 Isar 구현체.
- Flutter Navigator 명명 라우트, `WriteEditArgs`로 작성·상세·수정 전달.
- 앱 시작 시 저장소·Firebase·광고 초기화 후 `LockGate`, `SyncHost`, `PaymentServiceScope` 연결.
- iOS 플랫폼 연동은 `ios/Ketchup/SceneDelegate.swift`와 Dart 플랫폼 브리지에서 처리.
