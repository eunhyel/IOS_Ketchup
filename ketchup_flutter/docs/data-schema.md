# Ketchup Flutter 데이터·백업 스키마

기준: 2026-11-04 코드. 백업 스키마 버전과 앱 버전은 별개입니다.

## 로컬 저장

비로그인 보관함은 Documents의 `ketchup.isar`를 유지합니다. 로그인 보관함은 `Documents/accounts/ketchup_<UID SHA-256>/ketchup_<UID SHA-256>.isar`를 사용합니다. 각 DB에 다음 컬렉션을 등록합니다.

| 모델 | 주요 필드와 역할 |
|---|---|
| `IsarDiaryEntry` | `id`, `text`, `date`, `defaultImage`, `imagePath`, `createdAt`, `updatedAt` |
| `IsarDiarySyncMeta` | 일기와 같은 로컬 `id`, 고유 인덱스 `syncKey`(UUID) |
| `IsarAppSettings` | 단일 레코드 `id = 1`, 아래 설정 필드 |

일기의 `date`, `updatedAt`에 인덱스가 있습니다.
도메인 `DiaryEntry`는 이미지 바이너리가 아닌 nullable `imagePath`를 갖습니다.
이미지는 주로 `Documents/ketchup_images/`에 저장하고 DB에는 Documents 기준 상대 경로를 사용합니다.
구형 절대 경로도 읽으며 표시·복원 시 현재 디렉터리와 파일명을 기준으로 경로를 보정합니다.

### 설정

| 필드 | 의미 |
|---|---|
| `useLock` | 잠금 사용 |
| `fontName` | 선택한 글꼴 키 |
| `useCloudSync` | 레거시 호환 필드. Firestore 활성 조건이 아님 |
| `useIcloudSync` | iOS CloudKit 경로 활성화 |
| `blockRemoteDiaryRestore` | true이면 Firestore 원격 반영·iCloud 가져오기 억제 |
| `removeAds` | 레거시 호환 필드 |
| `removeAdsSubscriptionActive` | 스토어 구독에 의한 광고 제거 상태 |

뒤의 다섯 bool 필드는 Isar에서 nullable이며 기존 DB에 값이 없으면 false로 읽습니다.
초기화는 삭제 전에 `blockRemoteDiaryRestore`를 true로 저장합니다. 원격 정리가 실패하면 재실행 후에도 차단을 유지합니다.

### 별도 파일

- 보관함별 디렉터리의 `ketchup_lock.json`: 비밀번호의 SHA-256 해시.
- 보관함별 디렉터리의 `ketchup_compose_draft.json`: 신규 작성 임시 저장. `v`, `text`, `dateMs`, `defaultImage`, `imagePath`, `placeholder`.
- 위 두 JSON 파일 자체는 현재 Drive ZIP에 포함되지 않습니다.

## 현재 백업: ZIP 안의 v2 데이터

Drive 폴더 `Ketchup`의 `ketchup_backup.zip`을 같은 이름으로 갱신합니다.

```text
ketchup_backup.zip
├── ketchup_manifest.json
├── ketchup_data.isar
└── ketchup_images_bundle.json  (이미지가 있으면 포함)
```

매니페스트 필드:

| 필드 | 값 |
|---|---|
| `schemaVersion` | `2` |
| `exportedAt` | UTC ISO 8601 문자열 |
| `appVersion` | `APP_VERSION` 빌드 정의 또는 기본값 `1.1.11` |
| `files` | 파일명 → `{ "sha256": 문자열, "size": 바이트 수 }` |

이미지 번들은 `{ "schemaVersion": 1, "files": { "파일명": "Base64 데이터" } }` 구조입니다.
일기가 참조하는 이미지 파일만 수집합니다. 참조 파일 누락·읽기 실패·빈 파일 또는 같은 파일명의 서로 다른 이미지가 있으면 백업을 중단합니다.
이미지를 참조하는 일기가 없을 때만 이미지 번들을 생략합니다.

ZIP 업로드 성공 후 Drive에 남은 예전 분리형 매니페스트·Isar·이미지 번들 파일을 삭제 시도합니다.
삭제 실패는 이미 성공한 ZIP 백업을 실패 처리하지 않습니다.

## 복원 순서와 검증

1. `ketchup_backup.zip`.
2. 분리형 v2: `ketchup_manifest.json` + `ketchup_data.isar`, 선택적 이미지 번들.
3. `default.realm`: iOS 네이티브 Realm 파싱, 또는 같은 파일명에 담긴 과거 Isar 데이터 처리.
4. `ketchup_backup_v1.json`: 구형 JSON 가져오기.

앞 경로가 실패하면 가능한 다음 경로를 시도합니다.
Android에서 `default.realm`만 있고 ZIP·v2·v1이 없으면 복원을 거부합니다.
iOS에서 먼저 가져온 후 최신 ZIP으로 다시 백업하는 경로가 필요합니다.

- ZIP·분리형 v2는 `schemaVersion == 2`, Isar 파일 크기와 SHA-256을 검증한 후 DB를 교체합니다.
- 매니페스트에는 이미지 번들의 크기·해시도 쓰지만 현재 복원 경로는 이미지 번들에 동일한 검증을 수행하지 않습니다.
- 복원 전 화면에서 덮어쓰기 확인을 받고 현재 글꼴은 유지합니다.
- v1 JSON은 `schemaVersion == 1`인 일기를 가져오지만 `imageBase64`를 복원하지 않습니다. 설정은 기본값을 생성한 후 현재 글꼴을 적용합니다.
- 다른 스키마 버전의 자동 마이그레이션은 구현된 것으로 간주하지 않습니다.

구현 근거: `lib/src/core/storage/app_isar.dart`, `lib/src/features/diary/data/local/`,
`lib/src/features/settings/data/local/`, `lib/src/features/backup/data/ketchup_drive_service.dart`,
`backup_manifest.dart`, `legacy_backup_import.dart`.

## 원격 데이터

Firestore 문서 필드·충돌 처리·이미지 제한과 iCloud 동작은 [동기화 정책](sync-policy.md)을 참고합니다.
