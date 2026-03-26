# Ketchup Flutter 기능 명세 (1차 초안)

## 목표
- 기존 iOS `Ketchup` 앱의 핵심 경험을 Flutter(Android 우선)로 이식한다.
- 최종 목표는 iOS와 기능 100% 동등성(작성/수정/백업/복원/로그인/설정)이다.

## 핵심 화면

### 1) 메인 화면 (`ViewController` 대응)
- 월별 일기 목록 조회(기본은 최신 월 기준).
- 페이지 형태의 목록 탐색(이전/다음 월 이동).
- 데이터가 없을 때 안내 문구 표시.
- 상단 액션:
  - `작성` 버튼: 작성 화면 진입.
  - `설정` 버튼: 설정 화면/패널 진입.
- 앱 시작 시 조건부 잠금 화면 표시(비밀번호 설정 시).

### 2) 작성/상세/수정 화면 (`WriteView` 대응)
- 모드 3가지:
  - `view`: 읽기 전용 상세.
  - `write`: 신규 작성.
  - `edit`: 기존 수정.
- 입력 항목:
  - 본문 텍스트.
  - 날짜 선택(최대 오늘).
  - 이미지(갤러리 선택 또는 기본 이미지 랜덤).
- 액션:
  - 저장(신규/수정).
  - 삭제.
  - 닫기(변경사항 존재 시 확인 다이얼로그).
  - 인스타 스토리 공유.

### 3) 설정 화면 (`SettingView` 대응)
- 메뉴:
  - 암호 설정
  - 백업 및 동기화
  - 글씨체 변경
  - 개발자 한마디
  - 케찹의 역사(외부 링크)
  - 현재 버전 표시

### 4) 백업/복원 화면 (`BackUpView` 대응)
- Google 로그인/자동 로그인.
- Google Drive 백업:
  - 앱 전용 폴더(`Ketchup`) 확인/생성.
  - 백업 파일 업로드(중복 생성 대신 업데이트).
- Google Drive 복원:
  - 폴더 내 최신 백업 파일 탐색.
  - Realm + CoreData 파일 복원 시나리오 처리.
- **클라우드 동기화**: 설정의「클라우드 동기화」+ Firebase Auth 로그인 시 **Firestore** 양방향 동기화(정책은 `docs/sync-policy.md`). iOS 네이티브는 iCloud로 별도 설계 가능.

## 데이터 소스 및 흐름
- 로컬 저장소:
  - iOS: Realm + CoreData 병행.
  - Flutter: 단일 로컬 저장소로 통합(후보 Isar/Drift).
- 메인 목록 로드:
  - 시작 시 로컬 데이터 조회 -> UI 렌더링.
- 저장/수정/삭제:
  - 로컬 저장소 반영 -> 메인 목록 즉시 갱신.
- 백업/복원:
  - 로컬 파일 <-> Google Drive 파일 동기화.

## 이벤트/상태 요약
- 주요 이벤트:
  - `onCreateEntry`, `onUpdateEntry`, `onDeleteEntry`
  - `onOpenSettings`, `onOpenBackup`
  - `onGoogleLogin`, `onBackupRequested`, `onRestoreRequested`
- 주요 상태:
  - 로그인 여부
  - 로딩 여부(백업/복원 진행)
  - 일기 목록/선택 항목
  - 작성 화면 모드(view/write/edit)

## Flutter 1차 MVP 범위
- 포함:
  - 메인 목록 스켈레톤 UI
  - 작성 진입 버튼(FAB)
  - 설정/백업 진입점 UI
  - 더미 데이터 렌더링
- 제외(2차 이후):
  - 실제 DB 영속화
  - Google 로그인/Drive 연동
  - 복원 파이프라인
  - ~~클라우드 동기화~~ → Firestore 동기화(설정 토글) 반영됨

## 아키텍처 확정 (고정)
- 상태관리: Riverpod (확정)
- 레이어:
  - `features/` (화면 단위)
  - `domain/` (엔티티, 유즈케이스)
  - `data/` (로컬/원격 리포지토리)
- 리포지토리 패턴: `DiaryRepository` 인터페이스 + 구현체 주입
- 네비게이션: Flutter `Navigator` 명명 라우트(메인/작성/설정/백업) 1차 반영

## 핵심 도메인 구현 진행 현황 (3차)
- 메인 목록/작성/수정/설정(폰트/잠금) 화면의 상태 흐름을 Riverpod으로 반영.
- iOS 구조 대응 분리:
  - `DailyModel` -> `DiaryEntry` 엔티티
  - `DataRealm/CoreDataManager` -> `DiaryRepository` + `DiaryLocalDataSource(Isar)`
  - `UserDefaults(설정)` -> `SettingsRepository` + `SettingsLocalDataSource(Isar)`
- 기존 UX 상태 전이 반영:
  - 보기 -> 수정 전환
  - 수정/작성 중 변경사항 존재 시 닫기 확인 다이얼로그
  - 저장/삭제 후 목록 즉시 갱신
