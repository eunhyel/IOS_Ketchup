import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:ketchup_flutter/src/core/storage/app_documents.dart';

/// 일기 이미지 파일 경로: DB/JSON에는 문서 폴더 기준 **상대 경로**를 넣고, 표시 시 절대 경로로 풉니다.
/// (iOS `/var` ↔ `/private/var` 등 샌드박스 경로 차이에도 복원되도록 합니다.)
class DiaryImagePaths {
  DiaryImagePaths._();

  /// 절대 경로이면서 앱 Documents 아래면 상대 경로로 줄입니다. 그 외(임시 폴더 등)는 그대로 둡니다.
  static String? toStored(String? absolute) {
    if (absolute == null || absolute.trim().isEmpty) {
      return null;
    }
    final String trimmed = absolute.trim();
    // 이미 DB에 들어간 상대 경로는 그대로 둡니다.
    if (!p.isAbsolute(trimmed)) {
      return trimmed;
    }
    final String? root = AppDocuments.path;
    if (root == null) {
      return trimmed;
    }
    String abs = p.normalize(trimmed);
    String doc = p.normalize(root);
    try {
      final File f = File(abs);
      if (f.existsSync()) {
        abs = p.normalize(f.resolveSymbolicLinksSync());
      }
    } on Object {
      // ignore
    }
    try {
      final Directory d = Directory(doc);
      if (d.existsSync()) {
        doc = p.normalize(d.resolveSymbolicLinksSync());
      }
    } on Object {
      // ignore
    }
    final String sep = p.separator;
    if (abs.startsWith(doc + sep) || abs == doc) {
      final String rel = p.relative(abs, from: doc);
      if (rel.isNotEmpty && rel != '.') {
        return rel;
      }
    }
    return absolute.trim();
  }

  /// 저장된 문자열(상대/절대)을 실제 존재하는 파일의 절대 경로로 풉니다. 없으면 null.
  static String? resolveDisplay(String? stored) {
    if (stored == null || stored.trim().isEmpty) {
      return null;
    }
    final String s = stored.trim();
    final String? root = AppDocuments.path;

    final List<String> candidates = <String>[s];
    if (root != null) {
      if (!p.isAbsolute(s)) {
        candidates.add(p.join(root, s));
      }
      // 구 백업/타 기기 복원 시 절대경로(/var/.../ketchup_images/xxx.jpg)가 남아 있을 수 있어
      // 파일명 기준으로 현재 앱 Documents/ketchup_images에서도 항상 한 번 더 찾습니다.
      candidates.add(p.join(root, 'ketchup_images', p.basename(s)));
    }

    for (final String cand in candidates) {
      final File f = File(cand);
      if (f.existsSync()) {
        try {
          return p.normalize(f.resolveSymbolicLinksSync());
        } on Object {
          return p.normalize(cand);
        }
      }
    }

    if (p.isAbsolute(s)) {
      final File f = File(s);
      if (f.existsSync()) {
        try {
          return p.normalize(f.resolveSymbolicLinksSync());
        } on Object {
          return p.normalize(s);
        }
      }
    }
    return null;
  }
}
