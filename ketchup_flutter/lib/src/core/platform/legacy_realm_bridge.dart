import 'package:flutter/services.dart';

/// iOS 네이티브 Realm(`default.realm`) 파서를 호출합니다.
class LegacyRealmBridge {
  LegacyRealmBridge._();

  static const MethodChannel _channel = MethodChannel('com.o2a.ketchup/legacy_restore');

  /// `default.realm` 바이트를 네이티브에서 파싱해 엔트리 목록(Map)으로 반환합니다.
  static Future<List<Map<String, dynamic>>> parseRealmEntries(List<int> realmBytes) async {
    final dynamic raw = await _channel.invokeMethod<dynamic>(
      'parseLegacyRealmEntries',
      <String, dynamic>{
        'realm': Uint8List.fromList(realmBytes),
      },
    );
    final List<dynamic> list = (raw as List<dynamic>? ?? <dynamic>[]);
    return list
        .whereType<Map>()
        .map((Map e) => e.map((dynamic k, dynamic v) => MapEntry(k.toString(), v)))
        .cast<Map<String, dynamic>>()
        .toList();
  }
}
