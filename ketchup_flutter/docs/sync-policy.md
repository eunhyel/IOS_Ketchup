# Ketchup Flutter 동기화·초기화 정책

기준: 2026-11-04 코드. 운영 서버 설정이나 실제 기기 검증을 대신하지 않습니다.

## 활성 조건

| 경로 | 조건과 역할 |
|---|---|
| Firestore | 현재 보관함 소유 UID와 Firebase UID가 일치하고 초기화 차단이 없을 때 시작 |
| iCloud | 비로그인 보관함에서만, iOS이고 `useIcloudSync == true`인 경우 |
| Google Drive | Google 로그인·Drive 권한을 이용한 수동 파일 백업·복원 |

`SyncHost`는 설정·로그인 변경과 앱 복귀 시 동기화 구성을 다시 확인합니다.
iCloud 설정 UI는 `Platform.isIOS && !kReleaseMode`에서만 노출됩니다.
런타임 iCloud 경로 자체에는 release 차단 조건이 없으므로 기존 설정값도 고려해야 합니다.

## Firestore

문서 경로: `users/{uid}/diary_entries/{syncKey}`.
로컬 `IsarDiarySyncMeta`가 일기 id와 UUID `syncKey`를 연결합니다.

| 필드 | 형식·용도 |
|---|---|
| `syncKey` | UUID 문자열 |
| `text` | 본문 |
| `date`, `createdAt` | Firestore Timestamp |
| `defaultImage` | 기본 이미지 인덱스 |
| `imageBase64` | 선택적 Base64 문자열 또는 null |
| `updatedAtMs` | UTC epoch 밀리초 |
| `deleted` | 삭제 표시 |

- 시작 시 스냅샷 리스너를 연결하고 로컬이 비어 있으면 원격 전체 조회도 시도합니다. 이어 로컬 일기 전체 업로드를 호출합니다.
- 작성·수정은 로컬 저장 → 목록 갱신 → 비동기 원격 전송 순서입니다.
- 원격 반영 시 `updatedAtMs`를 비교하여 로컬 시각이 같거나 더 최신이면 무시합니다. 삭제 표시에도 동일한 비교를 적용합니다.
- 비교 기준은 기기에서 기록한 시각이며 서버 시각 기반 충돌 중재가 아닙니다.
- 삭제는 원격 삭제 표시를 먼저 전송 시도한 후 로컬 행·메타를 삭제합니다. 오래된 스냅샷으로 일기가 되살아나는 것을 줄이기 위해 해당 키의 반영을 잠시 억제합니다.
- Firestore SDK의 로컬 캐시와 쓰기 큐를 사용하며 별도의 앱 재전송 큐 테이블은 없습니다.

### 이미지

공용 이미지 읽기 함수는 원본 파일이 `750 * 1024`바이트를 넘으면 전송 데이터를 생략합니다.
이 제한은 Base64 변환 전 크기이며 최종 Firestore 문서 크기 보장을 뜻하지 않습니다.
기존 로컬 일기에 원격 이미지가 없으면 기존 이미지 경로를 유지하지만 신규 수신 일기에는 이미지가 없을 수 있습니다.
이 읽기 함수를 iCloud 업로드도 사용합니다.

## iCloud

- 컨테이너: `iCloud.com.ketchup`, private CloudKit DB.
- Flutter 저장 레코드: `FlutterDiaryDay`, 레코드 이름은 `syncKey`.
- 네이티브 브리지: `ios/Ketchup/SceneDelegate.swift`.
- 저장 필드: `id`, `text`, `date`, `defaultImage`, 선택적 `imageData`(CKAsset) 및 호환용 `CD_*` 필드.
- 설정을 켤 때 로컬이 있으면 전체 업로드, 비어 있으면 원격 가져오기를 시도합니다.
- 앱 시작·복귀 시에도 설정이 켜져 있고 로컬이 비어 있으면 가져오기를 시도합니다.
- 작성·수정 시 업로드, 개별 삭제 시 원격 레코드 삭제를 시도합니다.

Firestore의 실시간 리스너·`updatedAtMs` 충돌 정책과 동일하지 않습니다.
CloudKit 업로드·가져오기 실패를 위한 별도 영속 재시도 큐는 없습니다.

## 계정별 로컬 보관함

- 비로그인 일기와 기존 데이터는 원래 Documents의 `ketchup.isar`에 유지합니다. 로그인 계정에 자동 이관하지 않습니다.
- Google 계정은 Firebase UID를 SHA-256으로 변환한 이름의 별도 디렉터리·Isar DB를 사용합니다.
- 계정별 사진·작성 임시저장·설정·잠금 파일도 별도 디렉터리에 둡니다.
- 로그인·로그아웃 시 이전 화면과 ProviderScope를 해제하고 새 보관함을 엽니다. 로그아웃은 비로그인 보관함으로 돌아갑니다.
- 동기화 서비스는 생성 당시 소유 UID·세대 번호를 고정하고, 비동기 처리 후에도 같은 계정인지 검사합니다.
- iCloud는 Apple ID 단위이므로 Google 계정 보관함에서는 사용하지 않습니다. 비로그인 보관함의 기존 iCloud 경로만 유지합니다.

## 초기화와 복원 억제

1. 원격 반영 차단을 즉시 켜고 `blockRemoteDiaryRestore = true`를 저장합니다.
2. Firestore 리스너를 중단하고 이미 진행 중인 로컬 반영을 기다립니다. 늦게 도착한 응답은 세대 검사로 무시합니다.
3. iCloud 쓰기 작업이 진행 중이면 완료를 기다리고, 가져오기 결과의 적용을 취소합니다.
4. 현재 보관함의 일기·동기화 메타를 지우고 동기화 설정을 끕니다.
5. Google 계정은 대기 중인 Firestore 쓰기가 끝난 뒤 서버의 활성 일기를 삭제 표시로 변경합니다. 다른 기기에도 삭제가 전달되도록 문서를 직접 제거하지 않습니다.
6. 원격 처리까지 성공하면 Google 계정의 차단을 해제하고 완료를 안내합니다. 실패하면 차단을 유지하고 초기화 재시도를 안내합니다.

비로그인 iOS 보관함은 기존 CloudKit 삭제를 시도하되, 네이티브 삭제 결과의 한계를 고려해 자동 복원 차단을 유지합니다.
사용자가 iCloud를 명시적으로 다시 켜면 차단을 해제합니다.
Drive 백업 파일과 다른 계정의 로컬 보관함은 초기화 대상이 아닙니다.

## 운영 설정 확인

Firestore 규칙은 로그인 사용자가 자신의 `users/{uid}/diary_entries`에만 접근하도록 운영 콘솔에서 확인해야 합니다.
저장소 코드 확인만으로 배포된 규칙이나 클라우드 권한 상태를 확정하지 않습니다.

구현 근거: `lib/src/features/sync/`, `lib/src/features/diary/presentation/diary_providers.dart`,
`lib/src/features/backup/presentation/backup_page.dart`, `ios/Ketchup/SceneDelegate.swift`.
