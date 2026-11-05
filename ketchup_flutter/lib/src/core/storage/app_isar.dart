import 'package:ketchup_flutter/src/core/storage/app_documents.dart';
import 'package:isar_community/isar.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_sync_meta.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/isar_app_settings.dart';

class AppIsar {
  AppIsar._();

  /// Physical file name under the documents directory.
  static const String fileName = 'ketchup.isar';

  static Future<Isar> open({String? name, String? directory}) async {
    final dir = AppDocuments.directory();
    final dbName = name ?? AppDocuments.scopeName(AppDocuments.accountUid);
    final existing = Isar.getInstance(dbName);
    if (existing != null) return existing;
    return Isar.open(
      <CollectionSchema>[
        IsarDiaryEntrySchema,
        IsarDiarySyncMetaSchema,
        IsarAppSettingsSchema,
      ],
      directory: directory ?? dir.path,
      name: dbName,
      inspector: false,
    );
  }
}
