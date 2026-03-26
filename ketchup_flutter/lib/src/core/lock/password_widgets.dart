import 'package:flutter/material.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';

/// iOS `BlurPasswordLoginViewController` + `PasswordContainerView.xib` 와 동일한 수직 배치.
///
/// * 상단 여백: Storyboard `pYp-KL-DcX` — height = (width − 5) × 6/25
/// * 타이틀 ~ 도트: 31pt
/// * 도트 ~ 키패드: 46pt
/// * 키패드 폭: 305pt
class KetchupIosPasswordScene extends StatelessWidget {
  const KetchupIosPasswordScene({
    super.key,
    required this.screenWidth,
    required this.header,
    required this.digitCount,
    required this.filledCount,
    required this.onDigit,
    required this.onDelete,
  });

  final double screenWidth;
  final Widget header;
  final int digitCount;
  final int filledCount;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final double scale = screenWidth / 375.0;
    final double topSpacer = (screenWidth - 5) * 6 / 25;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: topSpacer),
        Center(
          child: SizedBox(
            width: 305 * scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                header,
                SizedBox(height: 31 * scale),
                KetchupPasswordDots(
                  digitCount: digitCount,
                  filledCount: filledCount,
                  scale: scale,
                ),
                SizedBox(height: 46 * scale),
                KetchupPasswordKeypad(
                  scale: scale,
                  onDigit: onDigit,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// XIB `PasswordDotView`: 이미지 65×65, 스택 간격 15.
class KetchupPasswordDots extends StatelessWidget {
  const KetchupPasswordDots({
    super.key,
    required this.digitCount,
    required this.filledCount,
    this.scale = 1.0,
  });

  final int digitCount;
  final int filledCount;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double dot = 65 * scale;
    final double gap = 15 * scale;

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < digitCount; i++) {
      if (i > 0) {
        children.add(SizedBox(width: gap));
      }
      final bool filled = i < filledCount;
      children.add(
        Image.asset(
          filled ? KetchupIosAssets.passwordKeyOn : KetchupIosAssets.passwordKeyOff,
          width: dot,
          height: dot,
          fit: BoxFit.contain,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}

/// XIB 키패드: 행 높이 92.5, 숫자 이미지 66, 가로 간격 15, 세로 간격 10, 삭제 `img-pw-dlt` 53.5×40.
class KetchupPasswordKeypad extends StatelessWidget {
  const KetchupPasswordKeypad({
    super.key,
    required this.scale,
    required this.onDigit,
    required this.onDelete,
  });

  final double scale;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final double rowW = 305 * scale;
    final double hGap = 15 * scale;
    final double vGap = 10 * scale;
    final double keyImg = 66 * scale;
    final double rowH = 92.5 * scale;
    final double cellW = (rowW - 2 * hGap) / 3;
    // XIB 리소스 `img-pw-dlt` — width 53.5pt, height 40pt (@1x 기준, 375 레이아웃과 동일 비율)
    final double deleteW = 53.5 * scale;
    final double deleteH = 40 * scale;

    Widget digitKey(int d) {
      return _KeyCell(
        width: cellW,
        height: rowH,
        onTap: () => onDigit(d),
        child: Image.asset(
          KetchupIosAssets.passwordDigit(d),
          width: keyImg,
          height: keyImg,
          fit: BoxFit.contain,
        ),
      );
    }

    Widget row3(int a, int b, int c) {
      return SizedBox(
        width: rowW,
        height: rowH,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            digitKey(a),
            SizedBox(width: hGap),
            digitKey(b),
            SizedBox(width: hGap),
            digitKey(c),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        row3(1, 2, 3),
        SizedBox(height: vGap),
        row3(4, 5, 6),
        SizedBox(height: vGap),
        row3(7, 8, 9),
        SizedBox(height: vGap),
        SizedBox(
          width: rowW,
          height: rowH,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(width: cellW, height: rowH),
              SizedBox(width: hGap),
              digitKey(0),
              SizedBox(width: hGap),
              _KeyCell(
                width: cellW,
                height: rowH,
                onTap: onDelete,
                child: Image.asset(
                  KetchupIosAssets.passwordDelete,
                  width: deleteW,
                  height: deleteH,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyCell extends StatelessWidget {
  const _KeyCell({
    required this.width,
    required this.height,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 탭 시 머티리얼 스플래시/하이라이트 없음 (네이티브 버튼 액션만)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}
