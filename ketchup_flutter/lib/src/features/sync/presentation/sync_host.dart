import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/backup/presentation/backup_providers.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';
import 'package:ketchup_flutter/src/features/sync/data/firestore_diary_sync_service.dart';
import 'package:ketchup_flutter/src/features/sync/presentation/sync_providers.dart';

/// 설정(클라우드 동기화) + 로그인 상태에 따라 Firestore 리스너를 붙였다 뗍니다.
class SyncHost extends ConsumerStatefulWidget {
  const SyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncHost> createState() => _SyncHostState();
}

class _SyncHostState extends ConsumerState<SyncHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconfigure());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppSettings>>(appSettingsProvider, (AsyncValue<AppSettings>? prev, AsyncValue<AppSettings> next) {
      _reconfigure();
    });
    ref.listen<AsyncValue<User?>>(firebaseUserProvider, (AsyncValue<User?>? prev, AsyncValue<User?> next) {
      _reconfigure();
    });
    return widget.child;
  }

  Future<void> _reconfigure() async {
    final FirestoreDiarySyncService sync = ref.read(firestoreDiarySyncProvider);
    sync.onRemoteApplied = () {
      unawaited(ref.read(diaryEntriesProvider.notifier).load());
    };
    final AppSettings? settings = ref.read(appSettingsProvider).valueOrNull;
    final User? user = ref.read(firebaseUserProvider).valueOrNull;
    final bool enabled = settings?.useCloudSync == true && user != null;
    await sync.start(enabled: enabled);
  }
}
