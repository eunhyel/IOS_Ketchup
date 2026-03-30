import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/platform/icloud_day_sync_bridge.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_local_provider.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_local_datasource.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_repository.dart';
import 'package:ketchup_flutter/src/features/diary/data/isar_diary_repository.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';
import 'package:ketchup_flutter/src/features/sync/presentation/sync_providers.dart';

final Provider<DiaryRepository> diaryRepositoryProvider = Provider<DiaryRepository>(
  (Ref ref) => IsarDiaryRepository(ref.watch(diaryLocalDataSourceProvider)),
);

class IcloudHydrationStats {
  const IcloudHydrationStats({
    required this.fetchedRows,
    required this.appliedRows,
    required this.rowsWithImagePayload,
    required this.rowsWithoutImagePayload,
    required this.imageSavedRows,
    required this.imageSaveFailedRows,
  });

  final int fetchedRows;
  final int appliedRows;
  final int rowsWithImagePayload;
  final int rowsWithoutImagePayload;
  final int imageSavedRows;
  final int imageSaveFailedRows;
}

class DiaryEntriesNotifier extends StateNotifier<AsyncValue<List<DiaryEntry>>> {
  DiaryEntriesNotifier(this._ref, this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final DiaryRepository _repository;

  Future<void> load() async {
    final AsyncValue<List<DiaryEntry>> next = await AsyncValue.guard(() async {
      await _repository.seedIfEmpty();
      return _repository.fetchAll();
    });
    if (!mounted) {
      return;
    }
    state = next;
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
    // 메인 그리드는 로컬 저장 직후 바로 갱신. Firestore/iCloud 는 네트워크 지연 없이 뒤에서 실행.
    await load();
    unawaited(_pushRemoteAfterLocalSave(saved));
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
    await load();
    unawaited(_pushRemoteAfterLocalSave(saved));
  }

  Future<void> _pushRemoteAfterLocalSave(DiaryEntry entry) async {
    await _pushUpsertQuietly(entry);
    await _pushIcloudQuietly(entry);
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
          ).timeout(const Duration(seconds: 2));
        } on Object catch (e, st) {
          debugPrint('[sync] tombstone 실패: $e $st');
        }
      }
      if (syncKey != null && Platform.isIOS) {
        final AppSettings? icloudOn = _ref.read(appSettingsProvider).valueOrNull;
        if (icloudOn?.useIcloudSync == true) {
          try {
            await IcloudDaySyncBridge.deleteDay(syncKey).timeout(const Duration(seconds: 8));
          } on Object catch (e, st) {
            debugPrint('[icloud] delete 실패: $e $st');
          }
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

  Future<void> _pushIcloudQuietly(DiaryEntry entry) async {
    if (!Platform.isIOS) {
      return;
    }
    final AppSettings? settings = _ref.read(appSettingsProvider).valueOrNull;
    if (settings?.useIcloudSync != true) {
      return;
    }
    try {
      final String syncKey = await _repository.getOrAssignSyncKey(entry.id);
      final DiaryLocalDataSource local = _ref.read(diaryLocalDataSourceProvider);
      final String? imageB64 = await local.readImageBase64ForSync(entry.imagePath);
      await IcloudDaySyncBridge.upsertDay(
        syncKey: syncKey,
        id: entry.id,
        text: entry.text,
        dateMs: entry.date.millisecondsSinceEpoch,
        defaultImage: entry.defaultImage,
        imageBase64: imageB64,
      );
    } on Object catch (e, st) {
      debugPrint('[icloud] push 실패: $e $st');
    }
  }

  /// iCloud 동기화를 켠 뒤에 한 번 호출해 로컬에 있는 일기를 모두 CloudKit에 올립니다.
  Future<void> icloudPushAllLocal() async {
    if (!Platform.isIOS) {
      return;
    }
    final AppSettings? settings = _ref.read(appSettingsProvider).valueOrNull;
    if (settings?.useIcloudSync != true) {
      return;
    }
    final List<DiaryEntry> all = await _repository.fetchAll();
    for (final DiaryEntry e in all) {
      try {
        await _pushIcloudQuietly(e).timeout(const Duration(seconds: 90));
      } on TimeoutException catch (_) {
        debugPrint('[icloud] pushAll local entry=${e.id} timeout');
      } on Object catch (err, st) {
        debugPrint('[icloud] pushAll local entry=${e.id} err: $err $st');
      }
    }
  }

  Future<bool> hasAnyLocalEntries() async {
    final List<DiaryEntry> rows = await _repository.fetchAll();
    return rows.isNotEmpty;
  }

  Future<IcloudHydrationStats> hydrateFromIcloudWithoutGoogle() async {
    final List<Map<String, dynamic>> rows = await IcloudDaySyncBridge.fetchDays().timeout(
      const Duration(seconds: 120),
      onTimeout: () {
        debugPrint('[icloud] fetchDays timeout');
        return <Map<String, dynamic>>[];
      },
    );
    debugPrint('[icloud] fetched rows: ${rows.length}');
    if (rows.isEmpty) {
      return const IcloudHydrationStats(
        fetchedRows: 0,
        appliedRows: 0,
        rowsWithImagePayload: 0,
        rowsWithoutImagePayload: 0,
        imageSavedRows: 0,
        imageSaveFailedRows: 0,
      );
    }

    int applied = 0;
    int withImagePayload = 0;
    int withoutImagePayload = 0;
    int imageSaved = 0;
    int imageSaveFailed = 0;
    for (final Map<String, dynamic> row in rows) {
      try {
        final int id = (row['id'] as num?)?.toInt() ?? -1;
        if (id < 0) {
          continue;
        }

        final String text = (row['text'] as String?) ?? '';
        final int defaultImage = (row['defaultImage'] as num?)?.toInt() ?? 0;
        final int dateMs = (row['dateMs'] as num?)?.toInt() ?? 0;
        final DateTime date =
            dateMs > 0 ? DateTime.fromMillisecondsSinceEpoch(dateMs) : DateTime.now();
        final String? imageBase64 = row['imageBase64'] as String?;
        final bool hasImagePayload = imageBase64 != null && imageBase64.isNotEmpty;
        if (hasImagePayload) {
          withImagePayload += 1;
        } else {
          withoutImagePayload += 1;
        }
        final String? imagePath = await _persistIcloudImageIfNeeded(imageBase64);
        if (hasImagePayload) {
          if (imagePath != null) {
            imageSaved += 1;
          } else {
            imageSaveFailed += 1;
          }
        }

        await _repository.upsertFromIcloud(
          id: id,
          text: text,
          date: date,
          defaultImage: defaultImage,
          imagePath: imagePath,
        );
        applied += 1;
      } on Object catch (e, st) {
        debugPrint('[icloud] row upsert 실패: $e $st / row=$row');
      }
    }

    await load();
    final IcloudHydrationStats stats = IcloudHydrationStats(
      fetchedRows: rows.length,
      appliedRows: applied,
      rowsWithImagePayload: withImagePayload,
      rowsWithoutImagePayload: withoutImagePayload,
      imageSavedRows: imageSaved,
      imageSaveFailedRows: imageSaveFailed,
    );
    debugPrint(
      '[icloud] stats fetched=${stats.fetchedRows} applied=${stats.appliedRows} '
      'withImage=${stats.rowsWithImagePayload} withoutImage=${stats.rowsWithoutImagePayload} '
      'imageSaved=${stats.imageSavedRows} imageSaveFailed=${stats.imageSaveFailedRows}',
    );
    return stats;
  }

  Future<String?> _persistIcloudImageIfNeeded(String? imageBase64) async {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return null;
    }
    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final Directory imgDir = Directory(p.join(dir.path, 'ketchup_images'));
      if (!await imgDir.exists()) {
        await imgDir.create(recursive: true);
      }
      final String dest = p.join(imgDir.path, 'icloud_${DateTime.now().microsecondsSinceEpoch}.jpg');
      await File(dest).writeAsBytes(base64Decode(imageBase64));
      return dest;
    } on Object catch (e, st) {
      debugPrint('[icloud] image save 실패: $e $st');
      return null;
    }
  }
}

final StateNotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>> diaryEntriesProvider =
    StateNotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>>(
  (Ref ref) => DiaryEntriesNotifier(ref, ref.watch(diaryRepositoryProvider)),
);
