import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_local_provider.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_repository.dart';
import 'package:ketchup_flutter/src/features/diary/data/isar_diary_repository.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/sync/presentation/sync_providers.dart';

final Provider<DiaryRepository> diaryRepositoryProvider = Provider<DiaryRepository>(
  (Ref ref) => IsarDiaryRepository(ref.watch(diaryLocalDataSourceProvider)),
);

class DiaryEntriesNotifier extends StateNotifier<AsyncValue<List<DiaryEntry>>> {
  DiaryEntriesNotifier(this._ref, this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final DiaryRepository _repository;

  Future<void> load() async {
    state = await AsyncValue.guard(() async {
      await _repository.seedIfEmpty();
      return _repository.fetchAll();
    });
  }

  Future<void> create({
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) async {
    final DiaryEntry saved = await _repository.create(
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
    );
    await _pushUpsertQuietly(saved);
    await load();
  }

  Future<void> update(
    int id, {
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) async {
    final DiaryEntry saved = await _repository.update(
      id,
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
    );
    await _pushUpsertQuietly(saved);
    await load();
  }

  Future<void> delete(int id) async {
    final String? syncKey = await _repository.syncKeyIfExists(id);
    final sync = _ref.read(firestoreDiarySyncProvider);

    if (syncKey != null) {
      sync.beginLocalDeleteSuppression(syncKey);
    }
    try {
      // 툼스톤을 먼저 올리고 나서 로컬 삭제. 기존 순서(로컬 삭제→툼스톤)는 메타 제거 직후
      // 스냅이 `deleted: false`만 오면 insertFromRemote로 행이 부활해 삭제가 한 번에 안 끝난 것처럼 보일 수 있음.
      if (syncKey != null) {
        try {
          await sync.pushTombstone(
            syncKey: syncKey,
            deletedAt: DateTime.now(),
          );
        } on Object catch (e, st) {
          debugPrint('[sync] tombstone 실패: $e $st');
        }
      }
      await _repository.delete(id);
    } finally {
      if (syncKey != null) {
        sync.endLocalDeleteSuppressionSoon(syncKey);
      }
    }
    await load();
  }

  Future<void> _pushUpsertQuietly(DiaryEntry entry) async {
    try {
      await _ref.read(firestoreDiarySyncProvider).pushUpsert(entry);
    } on Object catch (e, st) {
      debugPrint('[sync] push 실패: $e $st');
    }
  }
}

final StateNotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>> diaryEntriesProvider =
    StateNotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>>(
  (Ref ref) => DiaryEntriesNotifier(ref, ref.watch(diaryRepositoryProvider)),
);
