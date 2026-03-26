import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';

/// 표시 중인 달(일 단위는 무시, year/month만 사용).
final StateProvider<DateTime> diaryVisibleMonthProvider = StateProvider<DateTime>(
  (Ref ref) {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month);
  },
);

/// iOS `ViewController+Page` 와 동일: 일기가 있는 (년, 월)만 오름차순.
final Provider<List<DateTime>> diaryMonthsAscendingProvider = Provider<List<DateTime>>((Ref ref) {
  final AsyncValue<List<DiaryEntry>> all = ref.watch(diaryEntriesProvider);
  return all.maybeWhen(
    data: _distinctMonthsAscending,
    orElse: () => const <DateTime>[],
  );
});

List<DateTime> _distinctMonthsAscending(List<DiaryEntry> list) {
  final List<DiaryEntry> sorted = List<DiaryEntry>.from(list)
    ..sort((DiaryEntry a, DiaryEntry b) => a.date.compareTo(b.date));
  final Set<String> seen = <String>{};
  final List<DateTime> out = <DateTime>[];
  for (final DiaryEntry e in sorted) {
    final String key = '${e.date.year}-${e.date.month}';
    if (seen.add(key)) {
      out.add(DateTime(e.date.year, e.date.month));
    }
  }
  return out;
}

List<DiaryEntry> entriesInMonth(List<DiaryEntry> all, DateTime month) {
  final List<DiaryEntry> filtered = all
      .where((DiaryEntry e) => e.date.year == month.year && e.date.month == month.month)
      .toList();
  filtered.sort((DiaryEntry a, DiaryEntry b) => a.date.compareTo(b.date));
  return filtered;
}

final Provider<AsyncValue<List<DiaryEntry>>> diaryEntriesForVisibleMonthProvider =
    Provider<AsyncValue<List<DiaryEntry>>>((Ref ref) {
  final DateTime month = ref.watch(diaryVisibleMonthProvider);
  final AsyncValue<List<DiaryEntry>> all = ref.watch(diaryEntriesProvider);
  return all.whenData(
    (List<DiaryEntry> list) => list
        .where(
          (DiaryEntry e) => e.date.year == month.year && e.date.month == month.month,
        )
        .toList(),
  );
});
