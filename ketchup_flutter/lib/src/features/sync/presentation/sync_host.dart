import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/backup/presentation/backup_providers.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';
import 'package:ketchup_flutter/src/features/sync/data/firestore_diary_sync_service.dart';
import 'package:ketchup_flutter/src/features/sync/presentation/sync_providers.dart';

/// Google 로그인 시 Firestore 리스너를 붙이고, 로그아웃 시 뗍니다. (`useCloudSync` 토글과 무관)
class SyncHost extends ConsumerStatefulWidget {
  const SyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncHost> createState() => _SyncHostState();
}

class _SyncHostState extends ConsumerState<SyncHost> {
  late final AppLifecycleListener _lifecycle;
  bool _hydratingIcloudWithoutGoogle = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(_reconfigure());
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _reconfigure());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
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
    final bool enabled = user != null;
    debugPrint('[sync] reconfigure firestore=${enabled ? "on" : "off"} uid=${user?.uid}');
    await sync.start(enabled: enabled);

    // 재설치 복원 경로를 위해 Google 로그인 여부와 무관하게,
    // 로컬이 비어 있을 때만 iCloud hydrate를 시도합니다.
    final bool shouldHydrateFromIcloud = Platform.isIOS && settings?.useIcloudSync == true;
    if (shouldHydrateFromIcloud && !_hydratingIcloudWithoutGoogle) {
      _hydratingIcloudWithoutGoogle = true;
      try {
        final notifier = ref.read(diaryEntriesProvider.notifier);
        final bool hasLocal = await notifier.hasAnyLocalEntries();
        if (hasLocal) {
          debugPrint('[icloud] hydrate skipped: local entries already exist');
          return;
        }
        // 채널 등록/CloudKit 응답 지연으로 첫 호출이 빈 결과일 수 있어 짧게 재시도합니다.
        IcloudHydrationStats stats = await notifier.hydrateFromIcloudWithoutGoogle().timeout(
          const Duration(seconds: 120),
          onTimeout: () {
            debugPrint('[icloud] sync_host hydrate timeout (first)');
            return const IcloudHydrationStats(
              fetchedRows: 0,
              appliedRows: 0,
              rowsWithImagePayload: 0,
              rowsWithoutImagePayload: 0,
              imageSavedRows: 0,
              imageSaveFailedRows: 0,
            );
          },
        );
        if (stats.appliedRows == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          stats = await notifier.hydrateFromIcloudWithoutGoogle().timeout(
            const Duration(seconds: 120),
            onTimeout: () {
              debugPrint('[icloud] sync_host hydrate timeout (retry)');
              return const IcloudHydrationStats(
                fetchedRows: 0,
                appliedRows: 0,
                rowsWithImagePayload: 0,
                rowsWithoutImagePayload: 0,
                imageSavedRows: 0,
                imageSaveFailedRows: 0,
              );
            },
          );
        }
        debugPrint(
          '[icloud] hydrate applied=${stats.appliedRows}, '
          'withImage=${stats.rowsWithImagePayload}, '
          'withoutImage=${stats.rowsWithoutImagePayload}, '
          'imageSaved=${stats.imageSavedRows}, '
          'imageSaveFailed=${stats.imageSaveFailedRows}',
        );
      } finally {
        _hydratingIcloudWithoutGoogle = false;
      }
    }
  }
}
