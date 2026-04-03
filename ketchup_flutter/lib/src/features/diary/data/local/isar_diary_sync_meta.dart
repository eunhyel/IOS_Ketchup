import 'package:isar_community/isar.dart';

part 'isar_diary_sync_meta.g.dart';

/// 로컬 일기 행(`IsarDiaryEntry.id`)과 클라우드 문서 ID(`syncKey`, UUID)를 1:1로 연결합니다.
@collection
class IsarDiarySyncMeta {
  /// `IsarDiaryEntry.id`와 동일하게 둡니다(빠른 조회).
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: false)
  late String syncKey;
}
