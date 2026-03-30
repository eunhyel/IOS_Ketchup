import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IcloudDaySyncBridge {
  IcloudDaySyncBridge._();

  static const MethodChannel _channel = MethodChannel('com.o2a.ketchup/settings');

  static Future<List<Map<String, dynamic>>> fetchDays() async {
    if (!Platform.isIOS) {
      return <Map<String, dynamic>>[];
    }
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>('fetchICloudDays');
      final List<dynamic> list = (raw as List<dynamic>? ?? <dynamic>[]);
      return list
          .whereType<Map>()
          .map((Map e) => e.map((dynamic k, dynamic v) => MapEntry(k.toString(), v)))
          .cast<Map<String, dynamic>>()
          .toList();
    } catch (e, st) {
      debugPrint('iCloud 일기 fetch 실패: $e\n$st');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<int> clearDays() async {
    if (!Platform.isIOS) {
      return 0;
    }
    try {
      final int? deleted = await _channel.invokeMethod<int>('clearICloudDays');
      return deleted ?? 0;
    } catch (e, st) {
      debugPrint('iCloud 일기 삭제 실패: $e\n$st');
      return 0;
    }
  }

  /// Flutter 일기를 CloudKit `FlutterDiaryDay` 로 저장·갱신합니다. [syncKey]는 레코드 이름(고유).
  static Future<bool> upsertDay({
    required String syncKey,
    required int id,
    required String text,
    required int dateMs,
    required int defaultImage,
    String? imageBase64,
  }) async {
    if (!Platform.isIOS) {
      return false;
    }
    try {
      final Map<String, dynamic> args = <String, dynamic>{
        'syncKey': syncKey,
        'id': id,
        'text': text,
        'dateMs': dateMs,
        'defaultImage': defaultImage,
      };
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        args['imageBase64'] = imageBase64;
      }
      final dynamic raw = await _channel.invokeMethod<dynamic>('upsertICloudDay', args);
      return raw == true;
    } catch (e, st) {
      debugPrint('iCloud 일기 upsert 실패: $e\n$st');
      return false;
    }
  }

  /// [syncKey]에 해당하는 `FlutterDiaryDay` 레코드를 삭제합니다.
  static Future<bool> deleteDay(String syncKey) async {
    if (!Platform.isIOS) {
      return false;
    }
    if (syncKey.isEmpty) {
      return false;
    }
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>('deleteICloudDay', syncKey);
      return raw == true;
    } catch (e, st) {
      debugPrint('iCloud 일기 삭제 실패: $e\n$st');
      return false;
    }
  }

  static Future<Map<String, dynamic>> debugStatus() async {
    if (!Platform.isIOS) {
      return <String, dynamic>{
        'available': false,
        'zoneCount': 0,
        'changedRecords': 0,
        'mappableRows': 0,
        'nonMappableRecords': 0,
      };
    }
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>('debugICloudStatus');
      final Map<dynamic, dynamic> map = (raw as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{});
      return map.map((dynamic k, dynamic v) => MapEntry(k.toString(), v));
    } catch (e, st) {
      debugPrint('iCloud 진단 조회 실패: $e\n$st');
      return <String, dynamic>{
        'available': false,
        'zoneCount': 0,
        'changedRecords': 0,
        'mappableRows': 0,
        'nonMappableRecords': 0,
      };
    }
  }
}
