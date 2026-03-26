import 'dart:convert';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_image_paths.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_sync_meta.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:uuid/uuid.dart';

class DiaryLocalDataSource {
  const DiaryLocalDataSource(this._isar);

  final Isar _isar;

  static const Uuid _uuid = Uuid();
  static const int _maxImageBytesForSync = 750 * 1024;

  Future<List<DiaryEntry>> fetchAll() async {
    final List<IsarDiaryEntry> records = await _isar.isarDiaryEntrys.where().findAll();
    records.sort((IsarDiaryEntry a, IsarDiaryEntry b) => b.date.compareTo(a.date));
    return records.map((IsarDiaryEntry e) => e.toDomain()).toList();
  }

  Future<DiaryEntry?> getById(int id) async {
    final IsarDiaryEntry? found = await _isar.isarDiaryEntrys.get(id);
    return found?.toDomain();
  }

  /// 동기화용: 로컬 일기 id에 대응하는 클라우드 키. 없으면 새로 만들고 저장합니다.
  Future<String> getOrAssignSyncKey(int localDiaryId) async {
    final IsarDiarySyncMeta? existing = await _isar.isarDiarySyncMetas.get(localDiaryId);
    if (existing != null) {
      return existing.syncKey;
    }
    final String key = _uuid.v4();
    final IsarDiarySyncMeta meta = IsarDiarySyncMeta()
      ..id = localDiaryId
      ..syncKey = key;
    await _isar.writeTxn(() async {
      await _isar.isarDiarySyncMetas.put(meta);
    });
    return key;
  }

  /// 동기화용: 메타가 있을 때만 키 반환(삭제 툼스톤 등).
  Future<String?> getSyncKeyIfExists(int localDiaryId) async {
    final IsarDiarySyncMeta? meta = await _isar.isarDiarySyncMetas.get(localDiaryId);
    return meta?.syncKey;
  }

  Future<int?> findLocalIdBySyncKey(String syncKey) async {
    final IsarDiarySyncMeta? meta = await _isar.isarDiarySyncMetas.getBySyncKey(syncKey);
    return meta?.id;
  }

  Future<DiaryEntry> create({
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) async {
    final DateTime now = DateTime.now();
    final IsarDiaryEntry record = IsarDiaryEntry()
      ..text = text
      ..date = date
      ..defaultImage = defaultImage
      ..imagePath = DiaryImagePaths.toStored(imagePath)
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.isarDiaryEntrys.put(record);
      final IsarDiarySyncMeta meta = IsarDiarySyncMeta()
        ..id = record.id
        ..syncKey = _uuid.v4();
      await _isar.isarDiarySyncMetas.put(meta);
    });
    return record.toDomain();
  }

  Future<DiaryEntry> update(
    int id, {
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) async {
    final IsarDiaryEntry? found = await _isar.isarDiaryEntrys.get(id);
    if (found == null) {
      throw StateError('Diary entry not found: $id');
    }
    found
      ..text = text
      ..date = date
      ..defaultImage = defaultImage
      ..imagePath = DiaryImagePaths.toStored(imagePath)
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.isarDiaryEntrys.put(found);
    });
    return found.toDomain();
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.isarDiaryEntrys.delete(id);
      await _isar.isarDiarySyncMetas.delete(id);
    });
  }

  /// 원격에서 받은 내용으로 로컬 행을 덮어씁니다(동일 syncKey).
  Future<void> replaceFromRemote({
    required int localId,
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final IsarDiaryEntry? found = await _isar.isarDiaryEntrys.get(localId);
    if (found == null) {
      return;
    }
    found
      ..text = text
      ..date = date
      ..defaultImage = defaultImage
      ..imagePath = DiaryImagePaths.toStored(imagePath)
      ..createdAt = createdAt
      ..updatedAt = updatedAt;
    await _isar.writeTxn(() async {
      await _isar.isarDiaryEntrys.put(found);
    });
  }

  /// 원격에만 있는 일기를 로컬에 새로 만듭니다.
  Future<DiaryEntry> insertFromRemote({
    required String syncKey,
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final IsarDiaryEntry record = IsarDiaryEntry()
      ..text = text
      ..date = date
      ..defaultImage = defaultImage
      ..imagePath = DiaryImagePaths.toStored(imagePath)
      ..createdAt = createdAt
      ..updatedAt = updatedAt;

    await _isar.writeTxn(() async {
      await _isar.isarDiaryEntrys.put(record);
      final IsarDiarySyncMeta meta = IsarDiarySyncMeta()
        ..id = record.id
        ..syncKey = syncKey;
      await _isar.isarDiarySyncMetas.put(meta);
    });
    return record.toDomain();
  }

  Future<void> deleteLocalAndMeta(int localId) async {
    await _isar.writeTxn(() async {
      await _isar.isarDiaryEntrys.delete(localId);
      await _isar.isarDiarySyncMetas.delete(localId);
    });
  }

  /// 이미지 파일이 있으면 동기화 가능한 크기일 때만 base64.
  Future<String?> readImageBase64ForSync(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }
    try {
      final String path = DiaryImagePaths.resolveDisplay(imagePath) ?? imagePath;
      final File file = File(path);
      if (!await file.exists()) {
        return null;
      }
      final int len = await file.length();
      if (len > _maxImageBytesForSync) {
        return null;
      }
      final List<int> bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } on Object {
      return null;
    }
  }

  Future<bool> hasAny() async {
    return (await _isar.isarDiaryEntrys.count()) > 0;
  }

  Future<void> seedIfEmpty() async {
    // 첫 실행 시 더미 일기를 넣지 않습니다 (네이티브 Ketchup과 동일하게 빈 상태로 시작).
  }
}
