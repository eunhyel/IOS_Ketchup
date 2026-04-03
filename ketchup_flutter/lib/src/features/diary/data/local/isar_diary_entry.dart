import 'package:isar_community/isar.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_image_paths.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';

part 'isar_diary_entry.g.dart';

@collection
class IsarDiaryEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime date;

  late String text;
  late int defaultImage;
  String? imagePath;
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  DiaryEntry toDomain() {
    final String? resolved = DiaryImagePaths.resolveDisplay(imagePath);
    return DiaryEntry(
      id: id,
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: resolved ?? imagePath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static IsarDiaryEntry fromDomain(DiaryEntry entry) {
    return IsarDiaryEntry()
      ..id = entry.id
      ..text = entry.text
      ..date = entry.date
      ..defaultImage = entry.defaultImage
      ..imagePath = entry.imagePath
      ..createdAt = entry.createdAt
      ..updatedAt = entry.updatedAt;
  }
}
