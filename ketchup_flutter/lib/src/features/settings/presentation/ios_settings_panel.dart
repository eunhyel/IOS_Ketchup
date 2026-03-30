import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/features/backup/presentation/backup_page.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_font_picker_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_one_talk_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_password_setup_page.dart';

/// iOS `SettingView` — 왼쪽 280pt 패널 + 어두운 오버레이, 스와이프/탭으로 닫기.
Future<void> showKetchupIosSettingsPanel(BuildContext context, WidgetRef ref) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.57),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (BuildContext context, Animation<double> a1, Animation<double> a2) {
      final Size sz = MediaQuery.sizeOf(context);
      return SizedBox(
        width: sz.width,
        height: sz.height,
        child: const _IosSettingsPanelBody(),
      );
    },
    transitionBuilder: (BuildContext context, Animation<double> anim, Animation<double> _, Widget child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}

class _IosSettingsPanelBody extends ConsumerWidget {
  const _IosSettingsPanelBody();

  static const List<String> _menu = <String>[
    '암호 설정',
    '백업 및 동기화',
    '글씨체 변경',
    '개발자 한마디',
    '현재 버전',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double h = MediaQuery.sizeOf(context).height;
    const String version = '1.1.4';

    return Material(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            width: 280,
            height: h,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(KetchupIosAssets.bgPattern),
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView.separated(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 56),
                itemCount: _menu.length,
                separatorBuilder: (BuildContext context, int index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.13),
                ),
                itemBuilder: (BuildContext context, int index) {
                  String label = _menu[index];
                  if (index == _menu.length - 1) {
                    label = '$label  $version';
                  }
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _onTap(context, ref, index),
                      child: SizedBox(
                        height: 60,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: ketchupContentWeight(context),
                                color: const Color(0xFF303030),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, int index) async {
    Navigator.of(context).pop();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!context.mounted) {
      return;
    }
    switch (index) {
      case 0:
        await Navigator.of(context).pushNamed(IosPasswordSetupPage.routeName);
        break;
      case 1:
        await Navigator.of(context).pushNamed(BackupPage.routeName);
        break;
      case 2:
        await Navigator.of(context).pushNamed(IosFontPickerPage.routeName);
        break;
      case 3:
        await Navigator.of(context).pushNamed(IosOneTalkPage.routeName);
        break;
      case 4:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 버전: 1.1.4')),
        );
        break;
      default:
        break;
    }
  }
}
