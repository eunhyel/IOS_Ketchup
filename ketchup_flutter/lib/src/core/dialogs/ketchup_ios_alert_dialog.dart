import 'package:flutter/material.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';

/// iOS `CustomAlertView`(Alert.message) 스타일을 Flutter로 재현합니다.
/// - 배경 오버레이: rgba(0,0,0,0.4)
/// - 컨테이너: cornerRadius 40, 배경색 rgb(255,235,198)
/// - 상단: `img-alim-tit`
/// - 하단 버튼: `img-btn-bg` (54x54), 텍스트 컬러 동일
Future<bool?> showKetchupIosConfirmDialog(
  BuildContext context, {
  required String message,
  String leftText = '아니요',
  String rightText = '예',
}) {
  final double w = MediaQuery.sizeOf(context).width;
  final double scale = (w / 375.0).clamp(0.9, 1.2);

  const Color containerBg = Color(0xFFFFEBC6);
  const double containerW = 280;
  const double containerH = 183;

  return showGeneralDialog<bool?>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: containerW * scale,
            height: containerH * scale,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40 * scale),
              child: Container(
                color: containerBg,
                child: _IosAlertBody(
                  scale: scale,
                  message: message,
                  leftText: leftText,
                  rightText: rightText,
                  onLeft: () => Navigator.of(context).pop(false),
                  onRight: () => Navigator.of(context).pop(true),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _IosAlertBody extends StatelessWidget {
  const _IosAlertBody({
    required this.scale,
    required this.message,
    required this.leftText,
    required this.rightText,
    required this.onLeft,
    required this.onRight,
  });

  final double scale;
  final String message;
  final String leftText;
  final String rightText;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    const Color messageColor = Color(0xFF1D1D09);

    return Stack(
      children: <Widget>[
        // header part (message + title image)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 110.5 * scale,
          child: Padding(
            padding: EdgeInsets.only(top: 10 * scale),
            child: Column(
              children: <Widget>[
                Image.asset(
                  KetchupIosAssets.popupAlimTit,
                  width: 90 * scale,
                  height: 40 * scale,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 20 * scale),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 27 * scale),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: messageColor,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // footer buttons
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 75.5 * scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 63 * scale),
                child: _IosAlertButton(
                  scale: scale,
                  title: leftText,
                  onTap: onLeft,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 63 * scale),
                child: _IosAlertButton(
                  scale: scale,
                  title: rightText,
                  onTap: onRight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IosAlertButton extends StatelessWidget {
  const _IosAlertButton({
    required this.scale,
    required this.title,
    required this.onTap,
  });

  final double scale;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF1D1D09);
    final double size = 54 * scale;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(KetchupIosAssets.popupBtnBg),
              fit: BoxFit.contain,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: textColor,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

