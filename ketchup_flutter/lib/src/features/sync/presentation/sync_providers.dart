import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/backup/presentation/backup_providers.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_local_provider.dart';
import 'package:ketchup_flutter/src/features/sync/data/firestore_diary_sync_service.dart';

final Provider<FirebaseFirestore> firebaseFirestoreProvider =
    Provider<FirebaseFirestore>((Ref ref) => FirebaseFirestore.instance);

final Provider<FirestoreDiarySyncService> firestoreDiarySyncProvider =
    Provider<FirestoreDiarySyncService>((Ref ref) {
  final FirestoreDiarySyncService svc = FirestoreDiarySyncService(
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
    diaryLocal: ref.watch(diaryLocalDataSourceProvider),
  );
  ref.onDispose(() {
    // ignore: discarded_futures
    svc.stop();
  });
  return svc;
});
