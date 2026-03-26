import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_local_datasource.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_image_paths.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Firebase Firestore 기반 일기 동기화 (Android 권장). iOS Flutter 빌드에서도 동일 코드로 동작하며,
/// 네이티브 iOS 앱은 별도 iCloud 정책을 택할 수 있습니다.
///
/// 정책: [docs/sync-policy.md]
class FirestoreDiarySyncService {
  FirestoreDiarySyncService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required DiaryLocalDataSource diaryLocal,
  })  : _firestore = firestore,
        _auth = auth,
        _diaryLocal = diaryLocal;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DiaryLocalDataSource _diaryLocal;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  Timer? _refreshDebounce;
  bool _applyingRemote = false;
  String? _activeUid;

  /// 로컬에서 삭제하는 동안 Firestore가 아직 `deleted: false`인 캐시 스냅을 보내면
  /// [findLocalIdBySyncKey] 가 null이 되어 `insertFromRemote`로 행이 되살아날 수 있음.
  final Set<String> _suppressStaleNonDeletedApply = <String>{};

  /// 원격 반영 후 로컬 목록 갱신(디바운스).
  void Function()? onRemoteApplied;

  CollectionReference<Map<String, dynamic>>? _entriesCol(String uid) {
    return _firestore.collection('users').doc(uid).collection('diary_entries');
  }

  Future<void> start({required bool enabled}) async {
    await stop();
    if (!enabled) {
      return;
    }
    final User? user = _auth.currentUser;
    if (user == null) {
      debugPrint('[sync] 로그인 필요 — 클라우드 동기화 대기');
      return;
    }
    _activeUid = user.uid;
    final CollectionReference<Map<String, dynamic>> col = _entriesCol(user.uid)!;

    _sub = col.snapshots(includeMetadataChanges: false).listen(
      (QuerySnapshot<Map<String, dynamic>> snap) async {
        if (_applyingRemote) {
          return;
        }
        for (final DocumentChange change in snap.docChanges) {
          final DocumentSnapshot<Map<String, dynamic>> doc =
              change.doc as DocumentSnapshot<Map<String, dynamic>>;
          if (!doc.exists) {
            continue;
          }
          await _applyRemoteDoc(doc);
        }
        _scheduleRefresh();
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[sync] 스냅샷 오류: $e $st');
      },
    );

    await pushAllLocal();
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      onRemoteApplied?.call();
    });
  }

  Future<void> stop() async {
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    await _sub?.cancel();
    _sub = null;
    _activeUid = null;
  }

  Future<void> pushAllLocal() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return;
    }
    final List<DiaryEntry> all = await _diaryLocal.fetchAll();
    for (final DiaryEntry e in all) {
      await pushUpsert(e);
    }
    _scheduleRefresh();
  }

  Future<void> pushUpsert(DiaryEntry entry) async {
    final User? user = _auth.currentUser;
    if (user == null || _activeUid != user.uid) {
      return;
    }
    final String syncKey = await _diaryLocal.getOrAssignSyncKey(entry.id);
    final String? imageB64 = await _diaryLocal.readImageBase64ForSync(entry.imagePath);
    final CollectionReference<Map<String, dynamic>> col = _entriesCol(user.uid)!;
    final int updatedAtMs = entry.updatedAt.toUtc().millisecondsSinceEpoch;

    await col.doc(syncKey).set(<String, dynamic>{
      'syncKey': syncKey,
      'text': entry.text,
      'date': Timestamp.fromDate(entry.date.toUtc()),
      'defaultImage': entry.defaultImage,
      'imageBase64': imageB64,
      'createdAt': Timestamp.fromDate(entry.createdAt.toUtc()),
      'updatedAtMs': updatedAtMs,
      'deleted': false,
    }, SetOptions(merge: true));
  }

  /// [delete]에서 툼스톤 전 로컬 메타가 사라지기 전에 호출해, 오래된 풀 문서 스냅이 복구하지 못하게 합니다.
  void beginLocalDeleteSuppression(String syncKey) {
    if (syncKey.isEmpty) {
      return;
    }
    _suppressStaleNonDeletedApply.add(syncKey);
  }

  void endLocalDeleteSuppressionSoon(String syncKey, {Duration after = const Duration(seconds: 3)}) {
    if (syncKey.isEmpty) {
      return;
    }
    Future<void>.delayed(after, () {
      _suppressStaleNonDeletedApply.remove(syncKey);
    });
  }

  Future<void> pushTombstone({required String syncKey, required DateTime deletedAt}) async {
    final User? user = _auth.currentUser;
    if (user == null || _activeUid != user.uid) {
      return;
    }
    final CollectionReference<Map<String, dynamic>> col = _entriesCol(user.uid)!;
    final int ms = deletedAt.toUtc().millisecondsSinceEpoch;
    await col.doc(syncKey).set(<String, dynamic>{
      'syncKey': syncKey,
      'deleted': true,
      'updatedAtMs': ms,
    }, SetOptions(merge: true));
  }

  Future<void> _applyRemoteDoc(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final Map<String, dynamic>? data = doc.data();
    if (data == null) {
      return;
    }
    final String syncKey = (data['syncKey'] as String?) ?? doc.id;
    if (syncKey.isEmpty) {
      return;
    }
    final int remoteMs = (data['updatedAtMs'] as num?)?.toInt() ?? 0;
    final bool deleted = data['deleted'] as bool? ?? false;

    if (!deleted && _suppressStaleNonDeletedApply.contains(syncKey)) {
      return;
    }

    final int? localId = await _diaryLocal.findLocalIdBySyncKey(syncKey);

    if (deleted) {
      if (localId == null) {
        return;
      }
      final DiaryEntry? local = await _diaryLocal.getById(localId);
      if (local == null) {
        return;
      }
      final int localMs = local.updatedAt.toUtc().millisecondsSinceEpoch;
      if (localMs >= remoteMs) {
        return;
      }
      _applyingRemote = true;
      try {
        await _diaryLocal.deleteLocalAndMeta(localId);
      } finally {
        _applyingRemote = false;
      }
      return;
    }

    final String text = data['text'] as String? ?? '';
    final Timestamp? dateTs = data['date'] as Timestamp?;
    final int defaultImage = (data['defaultImage'] as num?)?.toInt() ?? 1;
    final Timestamp? createdTs = data['createdAt'] as Timestamp?;
    if (dateTs == null || createdTs == null) {
      return;
    }
    final DateTime date = dateTs.toDate().toLocal();
    final DateTime createdAt = createdTs.toDate().toLocal();
    final DateTime updatedAt = DateTime.fromMillisecondsSinceEpoch(remoteMs, isUtc: true).toLocal();

    String? imagePath;
    final String? b64 = data['imageBase64'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      imagePath = await _persistRemoteImageInDocuments(b64);
    }

    if (localId != null) {
      final DiaryEntry? local = await _diaryLocal.getById(localId);
      if (local != null) {
        final int localMs = local.updatedAt.toUtc().millisecondsSinceEpoch;
        if (localMs >= remoteMs) {
          return;
        }
      }
      _applyingRemote = true;
      try {
        await _diaryLocal.replaceFromRemote(
          localId: localId,
          text: text,
          date: date,
          defaultImage: defaultImage,
          imagePath: imagePath ?? local?.imagePath,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      } finally {
        _applyingRemote = false;
      }
      return;
    }

    _applyingRemote = true;
    try {
      await _diaryLocal.insertFromRemote(
        syncKey: syncKey,
        text: text,
        date: date,
        defaultImage: defaultImage,
        imagePath: imagePath,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } finally {
      _applyingRemote = false;
    }
  }

  /// 임시 디렉터리가 아닌 **Documents/ketchup_images** 에 저장해 앱 재시작 후에도 유지됩니다.
  Future<String?> _persistRemoteImageInDocuments(String b64) async {
    try {
      final Directory doc = await getApplicationDocumentsDirectory();
      final Directory imgDir = Directory(p.join(doc.path, 'ketchup_images'));
      if (!await imgDir.exists()) {
        await imgDir.create(recursive: true);
      }
      final String dest = p.join(imgDir.path, 'sync_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(dest).writeAsBytes(base64Decode(b64));
      return DiaryImagePaths.toStored(dest);
    } on Object catch (e) {
      debugPrint('[sync] 이미지 저장 실패: $e');
      return null;
    }
  }
}
