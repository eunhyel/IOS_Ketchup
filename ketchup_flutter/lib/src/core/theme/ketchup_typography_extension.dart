import 'package:flutter/material.dart';

/// 화면 곳곳의 `FontWeight(550)` 대신, 시스템/번들 글꼴에 맞는 굵기를 한곳에서 씁니다.
@immutable
class KetchupTypographyWeights extends ThemeExtension<KetchupTypographyWeights> {
  const KetchupTypographyWeights({required this.content});

  /// 본문·라벨 등에 쓰는 굵기 (시스템: 550, 번들 단일 페이스: 400).
  final FontWeight content;

  @override
  KetchupTypographyWeights copyWith({FontWeight? content}) {
    return KetchupTypographyWeights(content: content ?? this.content);
  }

  @override
  KetchupTypographyWeights lerp(ThemeExtension<KetchupTypographyWeights>? other, double t) {
    if (other is! KetchupTypographyWeights) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

FontWeight ketchupContentWeight(BuildContext context) {
  return Theme.of(context).extension<KetchupTypographyWeights>()?.content ?? FontWeight(550);
}
