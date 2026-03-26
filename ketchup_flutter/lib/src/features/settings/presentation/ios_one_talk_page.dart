import 'package:flutter/material.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';

/// iOS `OneTalkView.xib` 레이아웃 (375pt 기준, 스케일 적용).
class IosOneTalkPage extends StatelessWidget {
  const IosOneTalkPage({super.key});

  static const String routeName = '/one-talk';

  static const Color _textColor = Color(0xFF303030);

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final double scale = w / 375.0;

    Widget bubble(String asset, {required double left, required double top}) {
      return Positioned(
        left: left * scale,
        top: top * scale,
        width: 8 * scale,
        height: 13 * scale,
        child: Image.asset(asset, fit: BoxFit.contain),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(KetchupIosAssets.bgPattern),
            repeat: ImageRepeat.repeat,
            fit: BoxFit.none,
            alignment: Alignment.topLeft,
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // 닫기 32×32, safe top+20, leading+20 (XIB)
              Positioned(
                left: 20 * scale,
                top: 20 * scale,
                width: 32 * scale,
                height: 32 * scale,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Image.asset(
                      KetchupIosAssets.btnHdPrev,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // 제목: close trailing+12, top safe+25
              Positioned(
                left: 64 * scale,
                top: 25 * scale,
                child: Text(
                  '개발자 한마디',
                  style: TextStyle(
                    fontSize: 17 * scale,
                    color: Colors.black,
                    fontWeight: ketchupContentWeight(context),
                    height: 1.0,
                  ),
                ),
              ),
              // imgMem01
              Positioned(
                left: 22 * scale,
                top: 82 * scale,
                width: 81 * scale,
                height: 81 * scale,
                child: Image.asset(
                  KetchupIosAssets.developerMem(1),
                  fit: BoxFit.contain,
                ),
              ),
              bubble(KetchupIosAssets.developerBubble(1), left: 107, top: 126),
              // 첫 번째 말풍선 카드 (높이는 글씨에 맞춤)
              Positioned(
                left: 115 * scale,
                top: 109 * scale,
                width: 227.5 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      15.4 * scale,
                      8 * scale,
                      10 * scale,
                      8 * scale,
                    ),
                    child: Text(
                      '부자되게 해주세요!!\n제발요!!',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        color: _textColor,
                        fontWeight: ketchupContentWeight(context),
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),
              // imgMem02
              Positioned(
                left: 257 * scale,
                top: 225.5 * scale,
                width: 81 * scale,
                height: 81 * scale,
                child: Image.asset(
                  KetchupIosAssets.developerMem(2),
                  fit: BoxFit.contain,
                ),
              ),
              // 두 번째 말풍선 (Rh1-kW-b7h)
              Positioned(
                left: 27 * scale,
                top: 255.5 * scale,
                width: 212 * scale,
                height: 56 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      13 * scale,
                      9 * scale,
                      8 * scale,
                      6 * scale,
                    ),
                    child: Text(
                      '출시했습니다! \n덕분에 행복하네요 :)',
                      style: TextStyle(
                        fontSize: 17 * scale,
                        color: _textColor,
                        fontWeight: ketchupContentWeight(context),
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
              bubble(
                KetchupIosAssets.developerBubble(2),
                left: 239,
                top: 272.5,
              ),
              // imgMem03
              Positioned(
                left: 22 * scale,
                top: 379.5 * scale,
                width: 81 * scale,
                height: 81 * scale,
                child: Image.asset(
                  KetchupIosAssets.developerMem(3),
                  fit: BoxFit.contain,
                ),
              ),
              bubble(
                KetchupIosAssets.developerBubble(3),
                left: 110,
                top: 384.5,
              ),
              // 세 번째 말풍선 — 좌우 여백만 두고 넓혀 마지막 줄이 내려가지 않게
              Positioned(
                left: 118 * scale,
                top: 359.5 * scale,
                right: 14 * scale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      9 * scale,
                      10.5 * scale,
                      8 * scale,
                    ),
                    child: Text(
                      '케찹과 함께하는 \n여러분의 매일매일이 \n즐거운 순간으로 가득하길 : )',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 17 * scale,
                        color: _textColor,
                        fontWeight: ketchupContentWeight(context),
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
