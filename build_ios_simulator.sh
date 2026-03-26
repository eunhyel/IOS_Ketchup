#!/usr/bin/env bash
# 네이티브 Ketchup 앱을 시뮬레이터용으로 빌드합니다.
# 반드시 Ketchup.xcworkspace 를 사용해야 CocoaPods(Firebase 등) 모듈이 링크됩니다.
# Xcode에서 Ketchup.xcodeproj 만 열면 "Unable to find module dependency" 로 실패합니다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -d "Pods" ]]; then
  echo "Pods 폴더가 없습니다. pod install 실행 중..."
  pod install
fi

exec xcodebuild \
  -workspace Ketchup.xcworkspace \
  -scheme Ketchup \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
