import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_bundled_fonts.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';

class AppTheme {
  /// 기본 글꼴은 설정의 [fontKey]를 따릅니다.
  ///
  /// * **system** (또는 null): iOS XIB의 `system` 폰트와 같이 **기기 기본 산세리프**만 사용합니다.
  /// * **font_***: iOS 앱에 번들된 **동일한 .ttf/.otf** (Cafe24, 교보, 나눔 등)을 사용합니다.
  static ThemeData light({String? fontKey}) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFFED5151));
    final ThemeData base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      typography: Typography.material2021(platform: defaultTargetPlatform),
      scaffoldBackgroundColor: const Color(0xFFFDF8F4),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFFDF8F4),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFF0E8E2)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8DFD9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFED5151), width: 1.2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );

    final TextTheme mapped = _mapTextTheme(base.textTheme, fontKey);
    final TextTheme primaryMapped = _mapTextTheme(base.primaryTextTheme, fontKey);
    final FontWeight contentW = KetchupBundledFonts.contentWeightForSettingsKey(fontKey);
    return base.copyWith(
      textTheme: _appFontWeightTheme(mapped, contentW),
      primaryTextTheme: _appFontWeightTheme(primaryMapped, contentW),
      extensions: <ThemeExtension<dynamic>>[
        KetchupTypographyWeights(content: contentW),
      ],
    );
  }

  /// 앱 전역 글자 굵기: 시스템 글꼴은 **550**, 번들 단일 페이스는 **400** (iOS와 동일하게 합성 굵기 최소화).
  static TextTheme _appFontWeightTheme(TextTheme t, FontWeight contentWeight) {
    TextStyle? m(TextStyle? s) {
      if (s == null) {
        return null;
      }
      return s.copyWith(fontWeight: contentWeight);
    }

    return t.copyWith(
      displayLarge: m(t.displayLarge),
      displayMedium: m(t.displayMedium),
      displaySmall: m(t.displaySmall),
      headlineLarge: m(t.headlineLarge),
      headlineMedium: m(t.headlineMedium),
      headlineSmall: m(t.headlineSmall),
      titleLarge: m(t.titleLarge),
      titleMedium: m(t.titleMedium),
      titleSmall: m(t.titleSmall),
      bodyLarge: m(t.bodyLarge),
      bodyMedium: m(t.bodyMedium),
      bodySmall: m(t.bodySmall),
      labelLarge: m(t.labelLarge),
      labelMedium: m(t.labelMedium),
      labelSmall: m(t.labelSmall),
    );
  }

  static TextTheme _mapTextTheme(TextTheme theme, String? key) {
    final String? family = KetchupBundledFonts.familyForSettingsKey(key);
    if (family != null) {
      return theme.apply(
        fontFamily: family,
        bodyColor: theme.bodyLarge?.color,
        displayColor: theme.displayLarge?.color,
      );
    }
    switch (key) {
      case 'system':
      case null:
      default:
        return theme;
    }
  }
}
