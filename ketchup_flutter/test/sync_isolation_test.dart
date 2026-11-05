// SDK interface fakes are intentionally mutable test doubles.
// ignore_for_file: subtype_of_sealed_class, must_be_immutable

import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketchup_flutter/src/core/storage/app_documents.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_local_datasource.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/sync/data/firestore_diary_sync_service.dart';

class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Auth implements FirebaseAuth {
  @override
  User? currentUser = _User('a');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Doc implements DocumentReference<Map<String, dynamic>> {
  _Doc(this.col);
  final _Col col;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => col;
  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    col.writes++;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Col implements CollectionReference<Map<String, dynamic>> {
  int writes = 0;
  final stream =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Doc(this);
  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => stream.stream;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Firestore implements FirebaseFirestore {
  final col = _Col();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => col;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Snapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  List<DocumentChange<Map<String, dynamic>>> get docChanges => [_Change()];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Change implements DocumentChange<Map<String, dynamic>> {
  @override
  DocumentSnapshot<Map<String, dynamic>> get doc => _Remote();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Remote implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => true;
  @override
  String get id => 'entry';
  @override
  Map<String, dynamic> data() => {
    'syncKey': 'entry',
    'deleted': true,
    'updatedAtMs': 9999999999999,
  };
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Local implements DiaryLocalDataSource {
  Completer<String>? key;
  final lookupStarted = Completer<void>();
  Completer<int?>? lookup;
  int deletes = 0;
  @override
  Future<int?> findLocalIdBySyncKey(String key) async {
    lookupStarted.complete();
    return await lookup!.future;
  }

  @override
  Future<DiaryEntry?> getById(int id) async => DiaryEntry(
    id: id,
    text: 'local',
    date: DateTime(2026),
    defaultImage: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  @override
  Future<void> deleteLocalAndMeta(int id) async {
    deletes++;
  }

  @override
  Future<bool> hasAny() async => true;
  @override
  Future<List<DiaryEntry>> fetchAll() async => [];
  @override
  Future<String> getOrAssignSyncKey(int id) async =>
      key == null ? 'entry' : await key!.future;
  @override
  Future<String?> readImageBase64ForSync(String? path) async => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late Directory root;
  late _Auth auth;
  late _Firestore store;
  late _Local local;
  late FirestoreDiarySyncService service;
  final entry = DiaryEntry(
    id: 1,
    text: 'private',
    date: DateTime(2026),
    defaultImage: 0,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('sync_test');
    await AppDocuments.init(root: root);
    await AppDocuments.selectAccount('a');
    auth = _Auth();
    store = _Firestore();
    local = _Local();
    service = FirestoreDiarySyncService(
      firestore: store,
      auth: auth,
      diaryLocal: local,
    );
    await service.start(enabled: true);
  });
  tearDown(() async {
    await service.stop();
    await store.col.stream.close();
    await root.delete(recursive: true);
  });
  test(
    'late upload from previous account cannot reach another account',
    () async {
      local.key = Completer<String>();
      final upload = service.pushUpsert(entry);
      auth.currentUser = _User('b');
      await AppDocuments.selectAccount('b');
      local.key!.complete('entry');
      await upload;
      expect(store.col.writes, 0);
    },
  );
  test('reset gate blocks an upload already preparing image data', () async {
    local.key = Completer<String>();
    final upload = service.pushUpsert(entry);
    service.setSuppressRemoteApplyFromPersistedSettings(true);
    await service.stop();
    local.key!.complete('entry');
    await upload;
    await service.start(enabled: true);
    await service.pushUpsert(entry);
    expect(store.col.writes, 0);
  });
  test(
    'reset drains in-flight remote apply without modifying cleared local data',
    () async {
      local.lookup = Completer<int?>();
      store.col.stream.add(_Snapshot());
      await local.lookupStarted.future;
      service.setSuppressRemoteApplyFromPersistedSettings(true);
      final stopped = service.stop();
      local.lookup!.complete(1);
      await stopped;
      expect(local.deletes, 0);
    },
  );
  test('guest data is never uploaded to a signed-in account', () async {
    await service.stop();
    await AppDocuments.selectAccount(null);
    service = FirestoreDiarySyncService(
      firestore: store,
      auth: auth,
      diaryLocal: local,
    );
    await service.start(enabled: true);
    await service.pushUpsert(entry);
    expect(store.col.writes, 0);
  });
  test('current account can upload normally', () async {
    await service.pushUpsert(entry);
    expect(store.col.writes, 1);
  });
}
