import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DiaryAnalytics {
  DiaryAnalytics._();

  static Future<void>? _identity;

  static Future<void> _setIdentity(FirebaseAnalytics analytics) async {
    final root = await getApplicationSupportDirectory();
    await root.create(recursive: true);
    final file = File('${root.path}/analytics_installation_id');
    final String id;
    if (await file.exists()) {
      id = (await file.readAsString()).trim();
    } else {
      id = const Uuid().v4();
      final temporary = await File(
        '${file.path}.tmp',
      ).writeAsString(id, flush: true);
      await temporary.rename(file.path);
    }
    await analytics.setUserId(id: id);
  }

  static Future<void> logDiaryCreated() async {
    try {
      if ((!Platform.isAndroid && !Platform.isIOS) || Firebase.apps.isEmpty) {
        return;
      }
      final analytics = FirebaseAnalytics.instance;
      await (_identity ??= _setIdentity(analytics).onError<Object>((
        error,
        stack,
      ) {
        _identity = null;
        Error.throwWithStackTrace(error, stack);
      }));
      await analytics.logEvent(name: 'diary_created');
    } catch (error) {
      debugPrint('Diary analytics unavailable: ${error.runtimeType}');
    }
  }
}
