import 'dart:async';
import 'dart:collection';
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
import 'package:uuid/uuid.dart';

Uint8List _decodeBase64Isolate(String base64) => base64Decode(base64);
final Uuid _uuid = Uuid();

/// 간단한 세마포어 (Dart isolate/async 작업 동시성 제한용).
class _AsyncSemaphore {
  _AsyncSemaphore(this._max);

  final int _max;
  int _inFlight = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> _acquire() async {
    if (_inFlight < _max) {
      _inFlight += 1;
      return;
    }
    final Completer<void> c = Completer<void>();
    _waiters.addLast(c);
    await c.future;
    // 퍼밋은 _release()에서 이미 “다음 작업으로 이관”됐기 때문에
    // 여기서는 카운트를 증가시키지 않습니다.
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      // 다음 대기자에게 퍼밋을 넘깁니다.
      final Completer<void> c = _waiters.removeFirst();
      c.complete();
      return;
    }
    _inFlight -= 1;
  }

  Future<T> withPermit<T>(Future<T> Function() fn) async {
    await _acquire();
    try {
      return await fn();
    } finally {
      _release();
    }
  }
}

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
  Future<void> icloudPushAllLocal({void Function(int current, int total)? onProgress}) async {
    if (!Platform.isIOS) {
      return;
    }
    final AppSettings? settings = _ref.read(appSettingsProvider).valueOrNull;
    if (settings?.useIcloudSync != true) {
      return;
    }
    final List<DiaryEntry> all = await _repository.fetchAll();

    if (all.isEmpty) {
      return;
    }

    // 성능: CloudKit upsert는 네트워크/스레드 대기가 섞여 순차 처리시 N(예: 294)건이 크게 느려집니다.
    // 동시성 제한으로 병렬 upsert를 수행해 총 시간을 줄입니다.
    const int maxConcurrentUpserts = 3;
    final _AsyncSemaphore semaphore = _AsyncSemaphore(maxConcurrentUpserts);
    final DateTime start = DateTime.now();
    final int total = all.length;
    int pushedOk = 0;
    int completed = 0;

    // UI 진행상태 초기값 제공
    onProgress?.call(0, total);

    await Future.wait(
      all.map((DiaryEntry e) async {
        await semaphore.withPermit<void>(() async {
          try {
            await _pushIcloudQuietly(e).timeout(const Duration(seconds: 90));
            pushedOk += 1;
            // 너무 잦은 로그는 오히려 느리게 할 수 있어 50개 단위로만 출력합니다.
            if (pushedOk == 1 || pushedOk % 50 == 0) {
              final elapsed = DateTime.now().difference(start);
              debugPrint('[icloud] pushAllLocal success $pushedOk/$total elapsed=${elapsed.inSeconds}s');
            }
          } on TimeoutException catch (_) {
            debugPrint('[icloud] pushAll local entry=${e.id} timeout');
          } on Object catch (err, st) {
            debugPrint('[icloud] pushAll local entry=${e.id} err: $err $st');
          } finally {
            completed += 1;
            onProgress?.call(completed, total);
          }
        });
      }),
      // Future.wait가 fail-fast로 중단하지 않도록 각 task에서 예외를 흡수합니다.
    );
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

    // 이미지 저장은 1) 앱 문서 디렉토리 조회/존재확인 중복, 2) base64 디코드 CPU,
    // 3) 파일 I/O 순차 대기로 인해 느려질 수 있어 병렬화합니다.
    final Directory docDir = await getApplicationDocumentsDirectory();
    final Directory imgDir = Directory(p.join(docDir.path, 'ketchup_images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }

    int applied = 0;
    int withImagePayload = 0;
    int withoutImagePayload = 0;
    int imageSaved = 0;
    int imageSaveFailed = 0;

    // 먼저 모든 row를 파싱해두고, 이미지 디코드/저장만 동시성 제한으로 처리한 뒤
    // 마지막에 로컬 upsert + load()를 한 번만 수행합니다.
    final List<_IcloudHydrateItem> items = <_IcloudHydrateItem>[];
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
        items.add(
          _IcloudHydrateItem(
            id: id,
            text: text,
            date: date,
            defaultImage: defaultImage,
            imageBase64: hasImagePayload ? imageBase64 : null,
          ),
        );
      } on Object catch (e, st) {
        debugPrint('[icloud] row upsert 실패: $e $st / row=$row');
      }
    }

    // base64 디코드/저장 동시성 제한 (너무 높이면 CPU/메모리 폭주 가능).
    const int maxConcurrentImageSaves = 4;
    final _AsyncSemaphore semaphore = _AsyncSemaphore(maxConcurrentImageSaves);

    final List<Future<String?>> imageFutures = items.map((item) {
      if (item.imageBase64 == null) {
        return Future<String?>.value(null);
      }
      return semaphore.withPermit<String?>(() async {
        return _persistIcloudImageIfNeeded(item.imageBase64!, imgDir: imgDir);
      });
    }).toList(growable: false);

    final List<String?> imagePaths = await Future.wait(imageFutures);
    for (int i = 0; i < items.length; i++) {
      final _IcloudHydrateItem item = items[i];
      if (item.imageBase64 == null) {
        continue;
      }
      final String? imagePath = imagePaths[i];
      if (imagePath != null) {
        imageSaved += 1;
      } else {
        imageSaveFailed += 1;
      }
    }

    for (int i = 0; i < items.length; i++) {
      final _IcloudHydrateItem item = items[i];
      try {
        await _repository.upsertFromIcloud(
          id: item.id,
          text: item.text,
          date: item.date,
          defaultImage: item.defaultImage,
          imagePath: imagePaths[i],
        );
        applied += 1;
      } on Object catch (e, st) {
        debugPrint('[icloud] item upsert 실패: $e $st / id=${item.id}');
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

  Future<String?> _persistIcloudImageIfNeeded(
    String imageBase64, {
    required Directory imgDir,
  }) async {
    try {
      final String dest = p.join(imgDir.path, 'icloud_${_uuid.v4()}.jpg');
      final Uint8List bytes = await compute(_decodeBase64Isolate, imageBase64);
      await File(dest).writeAsBytes(bytes);
      return dest;
    } on Object catch (e, st) {
      debugPrint('[icloud] image save 실패: $e $st');
      return null;
    }
  }
}

class _IcloudHydrateItem {
  const _IcloudHydrateItem({
    required this.id,
    required this.text,
    required this.date,
    required this.defaultImage,
    required this.imageBase64,
  });

  final int id;
  final String text;
  final DateTime date;
  final int defaultImage;
  final String? imageBase64;
}

final StateNotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>> diaryEntriesProvider =
    StateNotifierProvider<DiaryEntriesNotifier, AsyncValue<List<DiaryEntry>>>(
  (Ref ref) => DiaryEntriesNotifier(ref, ref.watch(diaryRepositoryProvider)),
);
