# Ketchup Flutter 데이터/백업 스키마 (v1)

## 설계 목표
- iOS의 `DailyModel` 중심 구조를 Flutter 단일 모델로 정규화한다.
- 백업/복원 시 파일 누락 위험을 줄이기 위해 메타데이터 + 페이로드 구조를 사용한다.
- 스키마 버전 필드를 두어 마이그레이션 가능성을 확보한다.

## 도메인 모델

## `DiaryEntry`
- `id` (int): 로컬 고유 ID
- `text` (String): 일기 본문
- `date` (DateTime): 작성/기록 날짜
- `defaultImage` (int): 기본 이미지 인덱스
- `imageData` (Uint8List?, optional): 사용자 이미지 바이너리
- `createdAt` (DateTime)
- `updatedAt` (DateTime)

## `AppSettings`
- `useLock` (bool): 잠금 사용 여부
- `fontName` (String)
- `backupProvider` (String): `google_drive` 등
- `lastBackupAt` (DateTime?, optional)
- `schemaVersion` (int)

## 로컬 저장소 스키마 (확정)
- 저장소 선택: Isar (CoreData/Realm 통합 대상)
- 컬렉션:
  - `diary_entries`
  - `app_settings` (단일 레코드)
- 인덱스:
  - `diary_entries.date` (정렬/월 조회)
  - `diary_entries.updatedAt` (동기화 기준)

## 백업 포맷
- 파일명: `ketchup_backup_v1.json`
- MIME: `application/json`

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-03-20T00:00:00Z",
  "appVersion": "1.0.0",
  "settings": {
    "useLock": false,
    "fontName": "default",
    "backupProvider": "google_drive",
    "lastBackupAt": null
  },
  "entries": [
    {
      "id": 1,
      "text": "sample",
      "date": "2026-03-19T12:00:00Z",
      "defaultImage": 2,
      "imageBase64": null,
      "createdAt": "2026-03-19T12:00:00Z",
      "updatedAt": "2026-03-19T12:00:00Z"
    }
  ]
}
```

## 백업/복원 규칙
- `schemaVersion` 불일치 시:
  - 같은 major 범위면 마이그레이션 시도.
  - 지원 불가 버전은 사용자에게 안내 후 중단.
- 복원 정책:
  - 기본값: 전체 덮어쓰기(사용자 확인 필수).
  - 향후 옵션: 병합 복원(`updatedAt` 기준 최신 우선).
- 이미지:
  - v1은 `imageBase64` 인라인 저장.
  - 데이터가 커질 경우 v2에서 분리 ZIP 포맷 고려.

## Flutter 구현 매핑
- `DiaryEntry` <-> 기존 iOS `DailyModel`/`DataRealm`/`Day(CoreData)`
- `AppSettings` <-> `UserDefaults` 키 집합
- Google Drive 파일 구조:
  - 폴더: `Ketchup`
  - **v2 (현재 Flutter)**: `ketchup_manifest.json` + `ketchup_data.isar` (매니페스트에 SHA-256/크기로 무결성 검증)
  - **v1 (문서 스키마)**: `ketchup_backup_v1.json` — Drive에만 있을 경우 JSON으로 복원(이미지 인라인은 미연결)

## UI 에셋 (iOS 이식)
- 경로: `assets/ketchup_ios/` — Xcode `Ketchup/Assets.xcassets` **@2x** PNG를 단일 파일명으로 복사.
- **main**: `bg_pattern`, `img_logo`, `btn_hd_*`, `btn_page_*`
- **write**: `write_btnHdInsta`, `write_img_upload`, `img_default_0..2`
- **splash / 아이콘**: `splash_logo.png`, `app_icon_source.png`(1024, 런처 생성용)
- **backup**: `backup_imgGoogleDrive`, `backup_imgIcloud`
- **popup**: `popup_img_alim_tit`, `popup_img_btn_bg`
- **password**: `password_img_pw_0..9`, `password_img_pw_dlt`, `password_img_key_on/off`
- **developer / font**: `developer_*`, `font_img_ggomaeng`
- 코드에서 경로는 `KetchupIosAssets` 참고.

## 단계별 구현 상태
- 1차: In-memory repository + Riverpod 상태 흐름으로 화면/이벤트 먼저 고정
- 2차: Repository 구현을 Isar 기반으로 교체(인터페이스 유지)

## 테스트 기준
- 직렬화/역직렬화 round-trip 테스트
- 빈 데이터 백업/복원 테스트
- 이미지 포함 대용량 백업 테스트
- 버전 불일치 복원 실패 처리 테스트
