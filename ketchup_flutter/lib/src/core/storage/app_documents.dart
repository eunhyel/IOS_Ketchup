import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Guest data stays in the original directory. Account directories never migrate it.
class AppDocuments {
  AppDocuments._();
  static String? _root;
  static String? _path;
  static String? accountUid;
  static int generation = 0;
  static String scopeName(String? uid) =>
      uid == null ? 'ketchup' : 'ketchup_${sha256.convert(utf8.encode(uid))}';
  static Future<void> init({Directory? root}) async {
    _root = (root ?? await getApplicationDocumentsDirectory()).path;
    _path = _root;
  }

  static Future<void> selectAccount(String? uid) async {
    generation++;
    accountUid = uid;
    _path = uid == null ? _root : '${_root!}/accounts/${scopeName(uid)}';
    await directory().create(recursive: true);
  }

  static Directory directory() => Directory(_path!);
  static String? get path => _path;
}
