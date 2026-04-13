import 'dart:math' as math;

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
  /// 상단(메시지) + 하단(버튼) [Positioned] 높이 합과 일치해야 합니다. (이전 183은 186과 불일치 + Android 글리프로 Column 오버플로)
  const double containerH = 190;

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

/// iOS `CustomAlertView` 스타일로, 버튼을 1개만 표시합니다.
/// 본문 길이에 따라 가로·세로 크기가 늘어나며, 하단 버튼과 겹치지 않습니다.
Future<void> showKetchupIosSingleButtonDialog(
  BuildContext context, {
  required String message,
  String buttonText = '확인',
}) {
  final double w = MediaQuery.sizeOf(context).width;
  final double scale = (w / 375.0).clamp(0.9, 1.2);

  const Color containerBg = Color(0xFFFFEBC6);

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      final double maxDialogW = math.min(320 * scale, w - 32);
      return Center(
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.max(200, maxDialogW),
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40 * scale),
              child: Container(
                color: containerBg,
                child: _IosSingleAlertBody(
                  scale: scale,
                  message: message,
                  buttonText: buttonText,
                  onPressed: () => Navigator.of(context).pop(),
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
          height: 114.5 * scale,
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
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 27 * scale),
                    child: Center(
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

class _IosSingleAlertBody extends StatelessWidget {
  const _IosSingleAlertBody({
    required this.scale,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final double scale;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const Color messageColor = Color(0xFF1D1D09);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 10 * scale,
        left: 20 * scale,
        right: 20 * scale,
        bottom: 16 * scale,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image.asset(
            KetchupIosAssets.popupAlimTit,
            width: 90 * scale,
            height: 40 * scale,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 20 * scale),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: messageColor,
              height: 1.25,
            ),
          ),
          SizedBox(height: 20 * scale),
          Center(
            child: _IosAlertButton(
              scale: scale,
              title: buttonText,
              onTap: onPressed,
            ),
          ),
        ],
      ),
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

