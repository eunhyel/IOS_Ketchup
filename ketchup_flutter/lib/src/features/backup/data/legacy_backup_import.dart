import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_entry.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/isar_app_settings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Imports `ketchup_backup_v1.json` (schema v1) into an open [Isar].
class LegacyBackupImport {
  LegacyBackupImport._();

  static Future<void> importV1JsonIntoIsar(Isar isar, String jsonText) async {
    final Map<String, dynamic> root = json.decode(jsonText) as Map<String, dynamic>;
    final int? ver = root['schemaVersion'] as int?;
    if (ver != 1) {
      throw FormatException('지원하지 않는 v1 스키마 버전: $ver');
    }
    final List<dynamic> rawEntries = root['entries'] as List<dynamic>? ?? <dynamic>[];

    await isar.writeTxn(() async {
      await isar.isarDiaryEntrys.clear();
      await isar.isarAppSettings.clear();
      for (final dynamic item in rawEntries) {
        final Map<String, dynamic> e = item as Map<String, dynamic>;
        final DateTime date = DateTime.tryParse(e['date'] as String? ?? '') ?? DateTime.now();
        final DateTime createdAt =
            DateTime.tryParse(e['createdAt'] as String? ?? '') ?? date;
        final DateTime updatedAt =
            DateTime.tryParse(e['updatedAt'] as String? ?? '') ?? createdAt;
        final IsarDiaryEntry row = IsarDiaryEntry()
          ..text = e['text'] as String? ?? ''
          ..date = date
          ..defaultImage = (e['defaultImage'] as num?)?.toInt() ?? 0
          ..imagePath = null
          ..createdAt = createdAt
          ..updatedAt = updatedAt;
        final int? jsonId = (e['id'] as num?)?.toInt();
        if (jsonId != null && jsonId > 0) {
          row.id = jsonId;
        }
        await isar.isarDiaryEntrys.put(row);
      }
      await isar.isarAppSettings.put(
        IsarAppSettings()
          ..id = 1
          ..useLock = false
          ..fontName = 'system',
      );
    });
  }

  static bool looksLikeV1(String jsonText) {
    try {
      final Map<String, dynamic> root = json.decode(jsonText) as Map<String, dynamic>;
      return root['schemaVersion'] == 1 && root['entries'] is List;
    } catch (_) {
      return false;
    }
  }

  /// iOS 기존 `default.realm`에서 추출한 엔트리(Map)를 Isar로 가져옵니다.
  static Future<void> importLegacyRealmEntriesIntoIsar(
    Isar isar,
    List<Map<String, dynamic>> rawEntries,
  ) async {
    final Directory doc = await getApplicationDocumentsDirectory();
    final Directory imgDir = Directory(p.join(doc.path, 'ketchup_images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }

    await isar.writeTxn(() async {
      await isar.isarDiaryEntrys.clear();
      await isar.isarAppSettings.clear();
      for (final Map<String, dynamic> e in rawEntries) {
        final int id = (e['id'] as num?)?.toInt() ?? 0;
        final String text = e['text'] as String? ?? '';
        final int defaultImage = ((e['defaultImage'] as num?)?.toInt() ?? 0).clamp(0, 2);
        final int? dateMs = (e['dateMs'] as num?)?.toInt();
        final DateTime date = dateMs == null
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(dateMs, isUtc: false);

        String? imagePath;
        final String? imageB64 = e['imageBase64'] as String?;
        if (imageB64 != null && imageB64.isNotEmpty) {
          try {
            final Uint8List bytes = base64Decode(imageB64);
            final String filePath = p.join(
              imgDir.path,
              'legacy_${id}_$dateMs.jpg',
            );
            await File(filePath).writeAsBytes(bytes, flush: true);
            imagePath = p.relative(filePath, from: doc.path);
          } on Object {
            imagePath = null;
          }
        }

        final IsarDiaryEntry row = IsarDiaryEntry()
          ..text = text
          ..date = DateTime(date.year, date.month, date.day)
          ..defaultImage = defaultImage
          ..imagePath = imagePath
          ..createdAt = date
          ..updatedAt = date;
        if (id > 0) {
          row.id = id;
        }
        await isar.isarDiaryEntrys.put(row);
      }
      await isar.isarAppSettings.put(
        IsarAppSettings()
          ..id = 1
          ..useLock = false
          ..fontName = 'system',
      );
    });
  }
}
