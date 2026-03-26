# iOS 실기기에서 `flutter run` / 설치가 안 될 때

## 1) 워크스페이스 참조 오류 (프로젝트 수정됨)

`ios/Ketchup.xcworkspace/contents.xcworkspacedata`에 **없는 `Ketchup.xcodeproj`** 가 들어가 있으면 Xcode가 워크스페이스를 제대로 열지 못하거나, Flutter가 **“Installing and launching…”** 에서 오래 멈출 수 있습니다.

- 올바른 구성: `Ketchup.xcodeproj` + `Pods/Pods.xcodeproj` 만 참조

## 2) macOS 자동화(Automation) 권한

Xcode 26 + iOS 17+ 실기기 디버그는 Flutter가 **Xcode를 자동으로 제어**하는 경로를 씁니다.

**시스템 설정 → 개인정보 보호 및 보안 → 자동화(Automation)** 에서  
터미널/Cursor/Android Studio 등이 **Xcode를 제어**할 수 있게 허용했는지 확인하세요.

## 3) LLDB 디버그 경로 이슈 시 (대안)

물리 기기 + Xcode 26에서는 기본으로 LLDB 디버깅이 켜져 있습니다. 문제가 있으면 Xcode 디버그 경로로 되돌려 보세요.

```bash
flutter config --no-enable-lldb-debugging
```

또는 일회성:

```bash
FLUTTER_LLDB_DEBUGGING=0 flutter run -d <기기_UDID>
```

## 4) 빌드만 검증 (설치와 분리)

스킴 이름이 `Runner`가 아니면 Flutter가 `--flavor <스킴이름>`을 요구합니다. 이 프로젝트는 스킴·플레이버가 `Ketchup`이며 Xcode에 `Debug-Ketchup` 등 빌드 구성이 있습니다.

```bash
cd ketchup_flutter
flutter build ios --simulator --no-codesign --flavor Ketchup
# 또는 실기기용(서명 필요)
flutter build ios --debug --no-codesign --flavor Ketchup
```

여기까지 성공하면 **컴파일/서명 설정은 정상**이고, 남은 문제는 대개 **설치/디버그 연결(위 2~3)** 쪽입니다.
