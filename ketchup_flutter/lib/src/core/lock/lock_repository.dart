import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// 로컬(앱 문서 디렉토리) 파일에 암호 해시를 저장합니다.
/// - iOS: `UserDefaults` 기반
/// - Flutter: 동일한 동작을 위해 json 파일로 저장
class LockRepository {
  static const String fileName = 'ketchup_lock.json';

  Future<File> _lockFile() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  String _hash(String password) {
    final List<int> bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<String?> loadPasswordHash() async {
    try {
      final File f = await _lockFile();
      if (!await f.exists()) {
        return null;
      }
      final Map<String, dynamic> json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final Object? hash = json['hash'];
      return hash is String ? hash : null;
    } on Object {
      return null;
    }
  }

  Future<void> savePassword(String password) async {
    final File f = await _lockFile();
    final Map<String, dynamic> json = <String, dynamic>{
      'hash': _hash(password),
    };
    await f.writeAsString(jsonEncode(json));
  }

  Future<void> clearPassword() async {
    final File f = await _lockFile();
    if (await f.exists()) {
      await f.delete();
    }
  }
}

final Provider<LockRepository> lockRepositoryProvider = Provider<LockRepository>(
  (Ref ref) => LockRepository(),
);

