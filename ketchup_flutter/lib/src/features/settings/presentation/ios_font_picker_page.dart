import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_bundled_fonts.dart';
import 'package:ketchup_flutter/src/core/widgets/ketchup_ios_close_title_row.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

class IosFontPickerPage extends ConsumerWidget {
  const IosFontPickerPage({super.key});

  static const String routeName = '/font-picker';

  static const List<String> menu = <String>[
    '숑숑체',
    '손글씨체',
    '서라운드체',
    '아네모네에어체',
    '나눔스퀘어체',
    '리디바탕체',
  ];

  /// 라벨 -> 저장 키(고유) 매핑
  static const Map<String, String> _keyByLabel = <String, String>{
    '숑숑체': 'font_syong',
    '손글씨체': 'font_hand',
    '서라운드체': 'font_surround',
    '아네모네에어체': 'font_anemone',
    '나눔스퀘어체': 'font_nanum',
    '리디바탕체': 'font_ridi',
  };

  /// iOS 번들과 동일한 [pubspec] family 적용. (Google Fonts 대체 아님)
  TextStyle _applyFontKey({
    required String fontKey,
    required TextStyle base,
  }) {
    final String? family = KetchupBundledFonts.familyForSettingsKey(fontKey);
    if (family != null) {
      return base.copyWith(
        fontFamily: family,
        fontWeight: FontWeight.w400,
      );
    }
    return base;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settingsAsync = ref.watch(appSettingsProvider);
    final AppSettings? settings = settingsAsync.valueOrNull;

    final String currentKey = _normalizeFontKey(settings?.fontName);

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
          child: Column(
            children: <Widget>[
              KetchupIosCloseTitleRow(
                title: '글씨체 변경',
                onClose: () => Navigator.of(context).pop(),
              ),
              // iOS FontView: 카드 상단 = safeArea.top + 82, 헤더 높이 ≈ 52 → 간격 30
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  width: 325,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          KetchupIosAssets.fontGgomaeng,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        '우리집 꼬맹이 한컷 =)\n꼬맹이랑 하루종일 함께하는 주말이\n너무 행복해 @@',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17, color: Color(0xFF303030), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: menu.length,
                  separatorBuilder: (BuildContext context, int index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.13),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final String label = menu[index];
                    final String key = _keyByLabel[label]!;
                    final bool selected = key == currentKey;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await ref
                              .read(appSettingsProvider.notifier)
                              .setFontName(key);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                          child: Text(
                            label,
                            style: _applyFontKey(
                              fontKey: key,
                              base: TextStyle(
                                fontSize: 17,
                                color: selected
                                    ? const Color(0xFFED5151)
                                    : const Color(0xFF303030),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeFontKey(String? saved) {
    switch (saved) {
      case 'font_syong':
      case 'font_hand':
      case 'font_surround':
      case 'font_anemone':
      case 'font_nanum':
      case 'font_ridi':
        return saved!;
      // 구버전 값 호환
      case 'serif':
        return 'font_syong';
      case 'sans':
        return 'font_nanum';
      case 'system':
      default:
        return 'font_hand';
    }
  }
}
