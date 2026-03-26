import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_month_providers.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/write_edit_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_settings_panel.dart';

/// iOS `ViewController` + `BCItemPage` / `BCItemCell` 레이아웃에 맞춘 메인 화면.
class DiaryListPage extends ConsumerStatefulWidget {
  const DiaryListPage({super.key});

  static const String routeName = '/';

  @override
  ConsumerState<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends ConsumerState<DiaryListPage> {
  PageController? _pageController;
  String _monthsSignature = '';
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _syncController(List<DateTime> months) {
    final String sig = months.map((DateTime m) => '${m.year}-${m.month}').join('|');
    if (sig == _monthsSignature && _pageController != null) {
      return;
    }
    _monthsSignature = sig;
    _pageController?.dispose();
    if (months.isEmpty) {
      _pageController = null;
      _pageIndex = 0;
    } else {
      final int last = months.length - 1;
      _pageIndex = last;
      _pageController = PageController(initialPage: last);
    }
  }

  void _onPageChanged(int i, List<DateTime> months) {
    setState(() => _pageIndex = i);
    if (months.isNotEmpty && i >= 0 && i < months.length) {
      ref.read(diaryVisibleMonthProvider.notifier).state = months[i];
    }
  }

  void _goPage(int delta, int pageCount) {
    if (_pageController == null || pageCount < 2) {
      return;
    }
    final int next = (_pageIndex + delta).clamp(0, pageCount - 1);
    if (next == _pageIndex) {
      return;
    }
    _pageController!.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  /// 쓰기/수정 저장 후 일기가 속한 달로 헤더·PageView를 맞춥니다.
  void _handleWritePopResult(Object? result) {
    if (result is! DateTime) {
      return;
    }
    final DateTime targetMonth = DateTime(result.year, result.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _jumpToMonth(targetMonth);
    });
  }

  void _jumpToMonth(DateTime month) {
    final List<DateTime> months = ref.read(diaryMonthsAscendingProvider);
    final int idx = months.indexWhere(
      (DateTime m) => m.year == month.year && m.month == month.month,
    );
    if (idx < 0) {
      return;
    }
    ref.read(diaryVisibleMonthProvider.notifier).state = month;
    setState(() => _pageIndex = idx);
    if (_pageController == null) {
      return;
    }
    void runAnimate() {
      if (!mounted || _pageController == null || !_pageController!.hasClients) {
        return;
      }
      _pageController!.animateToPage(
        idx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    if (_pageController!.hasClients) {
      runAnimate();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => runAnimate());
    }
  }

  static String _defaultImageAsset(int defaultImage) => KetchupIosAssets.imgDefault(defaultImage);

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DiaryEntry>> entriesAsync = ref.watch(diaryEntriesProvider);
    final List<DateTime> months = ref.watch(diaryMonthsAscendingProvider);

    return entriesAsync.when(
      loading: () => _scaffold(
        context,
        months,
        const Center(child: CircularProgressIndicator(color: Color(0xFF5C5C5C))),
      ),
      error: (Object e, StackTrace st) => _scaffold(
        context,
        months,
        Center(child: Text('데이터 로드 실패: $e')),
      ),
      data: (List<DiaryEntry> allEntries) {
        _syncController(months);
        if (_pageController != null && months.isNotEmpty) {
          _pageIndex = _pageIndex.clamp(0, months.length - 1);
        }
        return _scaffold(context, months, _buildMainBody(context, allEntries, months));
      },
    );
  }

  Widget _scaffold(BuildContext context, List<DateTime> months, Widget body) {
    final DateTime now = DateTime.now();
    final DateTime headerMonth = months.isEmpty
        ? DateTime(now.year, now.month)
        : months[_pageIndex.clamp(0, months.length - 1)];

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _IosHeader(
                year: headerMonth.year,
                month: headerMonth.month,
                onSettings: () => showKetchupIosSettingsPanel(context, ref),
                onWrite: () async {
                  final Object? r = await Navigator.of(context).pushNamed(
                    WriteEditPage.routeName,
                    arguments: const WriteEditArgs.create(),
                  );
                  if (!mounted) {
                    return;
                  }
                  _handleWritePopResult(r);
                },
                monthCount: months.length,
                pageIndex: months.isEmpty ? 0 : _pageIndex.clamp(0, months.length - 1),
                onPrevMonth: () => _goPage(-1, months.length),
                onNextMonth: () => _goPage(1, months.length),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainBody(BuildContext context, List<DiaryEntry> allEntries, List<DateTime> months) {
    if (months.isEmpty || _pageController == null) {
      // iOS Main.storyboard `defult_label`: centerY 전체 뷰 대비 약 -80pt
      return Stack(
        children: <Widget>[
          Center(
            child: Transform.translate(
              offset: const Offset(0, -80),
              child: Text(
                '추억을 기록해주세요 =)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: ketchupContentWeight(context),
                  color: const Color(0xFF5C5C5C),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: (int i) => _onPageChanged(i, months),
      itemCount: months.length,
      itemBuilder: (BuildContext context, int index) {
        final List<DiaryEntry> monthEntries = entriesInMonth(allEntries, months[index]);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: monthEntries.length,
          itemBuilder: (BuildContext context, int i) {
            final DiaryEntry entry = monthEntries[i];
            return _IosDiaryCell(
              entry: entry,
              defaultAsset: _defaultImageAsset(entry.defaultImage),
              onTap: () async {
                final Object? r = await Navigator.of(context).pushNamed(
                  WriteEditPage.routeName,
                  arguments: WriteEditArgs.view(entry: entry),
                );
                if (!mounted) {
                  return;
                }
                _handleWritePopResult(r);
              },
            );
          },
        );
      },
    );
  }
}

class _IosHeader extends StatelessWidget {
  const _IosHeader({
    required this.year,
    required this.month,
    required this.onSettings,
    required this.onWrite,
    required this.monthCount,
    required this.pageIndex,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final int year;
  final int month;
  final VoidCallback onSettings;
  final VoidCallback onWrite;
  final int monthCount;
  final int pageIndex;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final bool hasPages = monthCount > 1;
    final bool canPrev = hasPages && pageIndex > 0;
    final bool canNext = hasPages && pageIndex < monthCount - 1;

    final String prevAsset = canPrev ? KetchupIosAssets.btnHdPrev : KetchupIosAssets.btnPagePrevDisa;
    final String nextAsset = canNext ? KetchupIosAssets.btnPageNext : KetchupIosAssets.btnPageNextDisa;

    return SizedBox(
      height: 169,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 4),
            SizedBox(
              height: 52,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 10),
                  _SquareImageButton(asset: KetchupIosAssets.btnHdMore, onTap: onSettings),
                  const SizedBox(width: 10),
                  Image.asset(
                    KetchupIosAssets.imgLogo,
                    height: 36.5,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  _SquareImageButton(asset: KetchupIosAssets.btnHdWrite, onTap: onWrite),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(width: 30),
                _MonthNavDot(asset: prevAsset, enabled: canPrev, onTap: canPrev ? onPrevMonth : null),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$year',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: ketchupContentWeight(context),
                          color: Colors.black,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '$month월',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.5,
                          fontWeight: ketchupContentWeight(context),
                          color: Colors.black,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                _MonthNavDot(asset: nextAsset, enabled: canNext, onTap: canNext ? onNextMonth : null),
                const SizedBox(width: 37),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareImageButton extends StatelessWidget {
  const _SquareImageButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _MonthNavDot extends StatelessWidget {
  const _MonthNavDot({
    required this.asset,
    required this.enabled,
    required this.onTap,
  });

  final String asset;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 26,
          height: 26,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _IosDiaryCell extends StatelessWidget {
  const _IosDiaryCell({
    required this.entry,
    required this.defaultAsset,
    required this.onTap,
  });

  final DiaryEntry entry;
  final String defaultAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? path = entry.imagePath;
    Widget imageChild;
    if (path != null) {
      final File f = File(path);
      if (f.existsSync()) {
        imageChild = Image.file(f, fit: BoxFit.cover);
      } else {
        imageChild = Image.asset(defaultAsset, fit: BoxFit.cover);
      }
    } else {
      imageChild = Image.asset(defaultAsset, fit: BoxFit.cover);
    }

    final int day = entry.date.day;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            imageChild,
            Positioned(
              left: 10,
              top: 5,
              child: Text(
                '$day',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: ketchupContentWeight(context),
                  height: 1,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      offset: const Offset(3, 3),
                      blurRadius: 3,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      offset: const Offset(1, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
