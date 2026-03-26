import 'package:flutter/material.dart';

/// iOS 네이티브 UI 텍스트 스타일 (XIB / Storyboard 기준).
///
/// [fontWeight]는 [KetchupTypographyWeights]와 맞춥니다 (시스템 550 / 번들 400).
class KetchupIosTextStyles {
  KetchupIosTextStyles._();

  /// [scale] = 화면 너비 / 375 (iOS 레이아웃 기준 폭).
  static TextStyle passwordScreenTitle(double scale, {required FontWeight fontWeight}) {
    return TextStyle(
      fontSize: 24 * scale,
      fontWeight: fontWeight,
      height: 1.0,
      color: Colors.black,
    );
  }
}
