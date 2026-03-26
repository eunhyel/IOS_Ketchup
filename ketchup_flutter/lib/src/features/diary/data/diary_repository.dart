import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';

abstract class DiaryRepository {
  Future<List<DiaryEntry>> fetchAll();
  Future<DiaryEntry?> getById(int id);
  Future<String?> syncKeyIfExists(int localId);
  Future<DiaryEntry> create({
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  });
  Future<DiaryEntry> update(
    int id, {
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  });
  Future<void> delete(int id);
  Future<void> seedIfEmpty();
}
