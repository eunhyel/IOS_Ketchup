import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/storage/isar_provider.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/settings_local_datasource.dart';
import 'package:ketchup_flutter/src/features/settings/data/settings_repository.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (Ref ref) => IsarSettingsRepository(SettingsLocalDataSource(ref.watch(isarProvider))),
);

class AppSettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  AppSettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
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
}

final StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>> appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AsyncValue<AppSettings>>(
  (Ref ref) => AppSettingsNotifier(ref.watch(settingsRepositoryProvider)),
);
