import 'package:flutter/material.dart';

/// iOS `AppDelegate` + `Resource/fonts`에 포함된 글꼴과 동일한 파일을 [pubspec.yaml]에 등록해 사용합니다.
/// (Flutter 쪽에서 Google Fonts로 **다른 글꼴**을 대입하던 것과 달리, 네이티브와 같은 실제 파일을 씁니다.)
class KetchupBundledFonts {
  KetchupBundledFonts._();

  /// [pubspec.yaml] `fonts:` 의 `family` 문자열과 동일해야 합니다.
  static const String syong = 'Cafe24Syongsyong';
  static const String hand = 'KyoboHandwriting2019';
  static const String surround = 'Cafe24SSurround';
  static const String anemone = 'Cafe24Ohsquareair';
  static const String nanum = 'NanumSquareOTF';
  static const String ridi = 'RidiBatang';

  /// 설정 키 → 번들에 등록한 family. `system` 등은 null.
  static String? familyForSettingsKey(String? key) {
    switch (key) {
      case 'font_syong':
        return syong;
      case 'font_hand':
        return hand;
      case 'font_surround':
        return surround;
      case 'font_anemone':
        return anemone;
      case 'font_nanum':
        return nanum;
      case 'font_ridi':
        return ridi;
      case 'serif':
        return syong;
      case 'sans':
        return nanum;
      case 'system':
      case null:
      default:
        return null;
    }
  }

  /// 번들 커스텀 글꼴은 단일 페이스라 iOS와 같이 **가짜 굵기 합성**을 피하려면 400에 가깝게 두는 편이 낫습니다.
  static bool isBundledKey(String? key) => familyForSettingsKey(key) != null;

  static FontWeight contentWeightForSettingsKey(String? key) =>
      isBundledKey(key) ? FontWeight.w400 : FontWeight(550);
}
