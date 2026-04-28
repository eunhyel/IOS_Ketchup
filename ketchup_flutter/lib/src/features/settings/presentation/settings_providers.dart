import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/storage/isar_provider.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/settings_local_datasource.dart';
import 'package:ketchup_flutter/src/features/settings/data/settings_repository.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (Ref ref) => IsarSettingsRepository(SettingsLocalDataSource(ref.watch(isarProvider))),
);

class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  AppSettingsNotifier(this._repository)
      : super(AsyncValue.data(_repository.loadSync())) {
    load();
  }

  final SettingsRepository _repository;

  Future<void> load() async {
    final AsyncValue<AppSettings> next = await AsyncValue.guard(_repository.load);
    if (!mounted) {
      return;
    }
    state = next;
  }

  Future<void> setUseLock(bool enabled) async {
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(previous.copyWith(useLock: enabled));
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setUseLock(enabled),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }

  Future<void> setFontName(String fontName) async {
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(previous.copyWith(fontName: fontName));
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setFontName(fontName),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }

  Future<void> setUseCloudSync(bool enabled) async {
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(previous.copyWith(useCloudSync: enabled));
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setUseCloudSync(enabled),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }

  Future<void> setUseIcloudSync(bool enabled) async {
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(previous.copyWith(useIcloudSync: enabled));
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setUseIcloudSync(enabled),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }

  Future<void> setBlockRemoteDiaryRestore(bool enabled) async {
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(previous.copyWith(blockRemoteDiaryRestore: enabled));
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setBlockRemoteDiaryRestore(enabled),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }

  /// 레거시/수동 토글용. `true`는 무시합니다(iOS·Android 공통: 스토어 구독으로만 광고 제거 ON).
  Future<void> setRemoveAds(bool enabled) async {
    if (enabled) {
      debugPrint(
        'AppSettingsNotifier.setRemoveAds(true) 무시 — 스토어 구독(구매/복원)으로만 광고 제거가 켜집니다.',
      );
      return;
    }
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(
        previous.copyWith(removeAds: false, removeAdsSubscriptionActive: false),
      );
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setRemoveAds(false),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }

  /// App Store / Play에서 구매·복원이 확정됐을 때만 호출합니다.
  Future<void> applyRemoveAdsFromStoreSubscription() async {
    final AppSettings? previous = state.valueOrNull;
    if (previous != null && mounted) {
      state = AsyncValue.data(
        previous.copyWith(removeAds: true, removeAdsSubscriptionActive: true),
      );
    }
    final AsyncValue<AppSettings> result = await AsyncValue.guard(
      () => _repository.setRemoveAds(true),
    );
    if (!mounted) {
      return;
    }
    state = result;
  }
}

final StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>> appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>(
  (Ref ref) => AppSettingsNotifier(ref.watch(settingsRepositoryProvider)),
);

/// 구독(광고 제거) 활성 — [AppSettings.removeAdsSubscriptionActive].
final Provider<bool> isSubscribedProvider = Provider<bool>(
  (Ref ref) => ref.watch(appSettingsProvider).valueOrNull?.isSubscribed ?? false,
);
