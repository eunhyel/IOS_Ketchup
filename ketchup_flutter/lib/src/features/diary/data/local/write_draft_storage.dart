import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:ketchup_flutter/src/features/diary/data/local/diary_image_paths.dart';

/// 쓰기 화면(신규 작성) 미저장 상태를 디바이스에 보관합니다.
/// (iOS `ImageFileManager` + 문서 디렉터리와 동일한 개념)
class WriteDraftStorage {
  WriteDraftStorage._();

  static const String _fileName = 'ketchup_compose_draft.json';
  static const int _version = 1;

  static Future<File> _file() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<void> save({
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
    required bool iosPlaceholderActive,
  }) async {
    try {
      final File f = await _file();
      final String? storedPath = DiaryImagePaths.toStored(imagePath);
      final Map<String, Object?> map = <String, Object?>{
        'v': _version,
        'text': text,
        'dateMs': date.millisecondsSinceEpoch,
        'defaultImage': defaultImage,
        'imagePath': storedPath,
        'placeholder': iosPlaceholderActive,
      };
      await f.writeAsString(jsonEncode(map));
    } on Object {
      // 저장 실패는 쓰기 UX를 막지 않음
    }
  }

  static Future<WriteDraftSnapshot?> load() async {
    try {
      final File f = await _file();
      if (!await f.exists()) {
        return null;
      }
      final Object? decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final Map<String, dynamic> m = decoded;
      if (m['v'] != _version) {
        return null;
      }
      final int? ms = m['dateMs'] as int?;
      if (ms == null) {
        return null;
      }
      final String text = m['text'] as String? ?? '';
      final int def = ((m['defaultImage'] as num?)?.toInt() ?? 0).clamp(0, 2);
      final String? rawImg = m['imagePath'] as String?;
      final String? img = DiaryImagePaths.resolveDisplay(rawImg);
      final bool ph = m['placeholder'] as bool? ?? false;
      return WriteDraftSnapshot(
        text: text,
        date: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: false),
        defaultImage: def,
        imagePath: img,
        iosPlaceholderActive: ph,
      );
    } on Object {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final File f = await _file();
      if (await f.exists()) {
        await f.delete();
      }
    } on Object {
      // ignore
    }
  }
}

class WriteDraftSnapshot {
  const WriteDraftSnapshot({
    required this.text,
    required this.date,
    required this.defaultImage,
    this.imagePath,
    required this.iosPlaceholderActive,
  });

  final String text;
  final DateTime date;
  final int defaultImage;
  final String? imagePath;
  final bool iosPlaceholderActive;
}
