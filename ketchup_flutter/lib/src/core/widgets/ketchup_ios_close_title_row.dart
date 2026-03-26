import 'package:flutter/material.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';

/// iOS `FontView` / `BackUpView` / `OneTalkView` XIB와 동일:
/// - `close_btn`: safeArea leading +20, top +20, 32×32 (`btn_hd_prev`)
/// - 타이틀 라벨: close trailing +12, top +25 (백키 대비 +5), 17pt 시스템 폰트
class KetchupIosCloseTitleRow extends StatelessWidget {
  const KetchupIosCloseTitleRow({
    super.key,
    required this.title,
    required this.onClose,
    this.scale = 1.0,
  });

  final String title;
  final VoidCallback onClose;

  /// 375pt 기준 스케일(BackUp/OneTalk 등 레이아웃과 동일)
  final double scale;

  @override
  Widget build(BuildContext context) {
    final double s = scale;
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 20 * s, 20 * s, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClose,
              child: SizedBox(
                width: 32 * s,
                height: 32 * s,
                child: Image.asset(
                  KetchupIosAssets.btnHdPrev,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * s),
          Padding(
            padding: EdgeInsets.only(top: 5 * s),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17 * s,
                fontWeight: ketchupContentWeight(context),
                color: const Color(0xFF303030),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
