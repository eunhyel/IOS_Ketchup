import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_sync_meta.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/isar_app_settings.dart';
import 'package:path_provider/path_provider.dart';

class AppIsar {
  AppIsar._();

  /// Physical file name under the documents directory.
  static const String fileName = 'ketchup.isar';

  static Future<Isar> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      <CollectionSchema>[
        IsarDiaryEntrySchema,
        IsarDiarySyncMetaSchema,
        IsarAppSettingsSchema,
      ],
      directory: dir.path,
      name: 'ketchup',
      inspector: false,
    );
  }
}
