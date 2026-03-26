# 클라우드 동기화 정책 (Ketchup Flutter)

## 플랫폼

| 플랫폼 | 기본 백엔드 | 비고 |
|--------|-------------|------|
| Android | **Firebase Firestore** | 앱 내 설정에서 켜면 동작 |
| iOS (Flutter) | 동일 Firestore 코드 경로 | 네이티브 Swift 앱은 **iCloud(CloudKit)** 등 별도 구현 가능 |
| Drive 백업 | Google Drive 파일 백업 | 문서 단위 실시간 동기화와는 별개 |

앱별로 **Firebase / iCloud** 둘 다 지원하도록 확장하려면, 동기화 포트(인터페이스)를 두고 플랫폼에 맞는 구현체를 주입하면 됩니다. 현재 Flutter 빌드는 Firestore 구현만 포함합니다.

## 동기화 방향

- **양방향**: 로컬(Isar) 변경 → Firestore upsert, Firestore 스냅샷 → 로컬 병합.
- **단방향 모드**는 추후 플래그로 추가 가능(예: “받기만”, “보내기만”).

## 충돌 해결

- 기준 필드: **`updatedAtMs`** (UTC epoch ms). **Last-Write-Wins (LWW)**.
- 로컬 `updatedAt`과 원격 `updatedAtMs`를 비교해 **같거나 로컬이 더 최신이면** 원격 변경을 무시합니다.
- **삭제(툼스톤)**: 문서에 `deleted: true` + `updatedAtMs`. 로컬이 더 최신이 아니면 로컬 행·메타 삭제.

## 오프라인 / 큐

- Firestore Android/iOS SDK **로컬 캐시 + 쓰기 큐**를 사용합니다 (`persistenceEnabled: true`).
- 네트워크가 없을 때 `set`/`merge`는 큐에 쌓였다가 온라인 시 전송됩니다.
- 별도 수동 큐 테이블은 두지 않습니다(필요 시 재시도 UI·로깅만 추가).

## 데이터 모델 (Firestore)

컬렉션: `users/{uid}/diary_entries/{syncKey}`

| 필드 | 설명 |
|------|------|
| `syncKey` | UUID, 문서 ID와 동일 권장 |
| `text`, `date`, `defaultImage`, `createdAt` | 일기 본문 |
| `imageBase64` | 선택, 약 **750KB 이하**만 동기화(초과 시 생략) |
| `updatedAtMs` | LWW 기준 |
| `deleted` | 툼스톤 |

로컬에서는 `IsarDiarySyncMeta`로 `일기 id` ↔ `syncKey`를 매핑합니다.

## 보안 규칙 (예시)

프로덕션 전에 Firebase Console에서 규칙을 반드시 제한하세요.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/diary_entries/{docId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 제한 사항

- 첨부 이미지는 용량 제한으로 동기화되지 않을 수 있습니다.
- 구버전 Isar에 `useCloudSync` 필드가 없을 수 있으나, nullable deserialize로 기본값 `false` 처리합니다.
