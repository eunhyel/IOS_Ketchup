import 'package:ketchup_flutter/src/features/diary/data/diary_repository.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_local_datasource.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';

class IsarDiaryRepository implements DiaryRepository {
  const IsarDiaryRepository(this._local);

  final DiaryLocalDataSource _local;

  @override
  Future<List<DiaryEntry>> fetchAll() => _local.fetchAll();

  @override
  Future<DiaryEntry?> getById(int id) => _local.getById(id);

  @override
  Future<String?> syncKeyIfExists(int localId) => _local.getSyncKeyIfExists(localId);

  @override
  Future<String> getOrAssignSyncKey(int localId) => _local.getOrAssignSyncKey(localId);

  @override
  Future<DiaryEntry> create({
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) {
    return _local.create(
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
    );
  }

  @override
  Future<DiaryEntry> update(
    int id, {
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) {
    return _local.update(
      id,
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
    );
  }

  @override
  Future<DiaryEntry> upsertFromIcloud({
    required int id,
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) {
    return _local.upsertFromIcloud(
      id: id,
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
    );
  }

  @override
  Future<void> delete(int id) => _local.delete(id);

  @override
  Future<void> seedIfEmpty() => _local.seedIfEmpty();
}
