import 'package:ketchup_flutter/src/features/settings/data/local/settings_local_datasource.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();

  /// DB에 저장된 설정을 동기로 읽습니다. 행이 없으면 [AppSettings.emptyDatabaseDefaults]와 같습니다.
  AppSettings loadSync();

  Future<AppSettings> setUseLock(bool enabled);
  Future<AppSettings> setFontName(String fontName);
  Future<AppSettings> setUseCloudSync(bool enabled);
  Future<AppSettings> setUseIcloudSync(bool enabled);
  Future<AppSettings> setBlockRemoteDiaryRestore(bool enabled);
  Future<AppSettings> setRemoveAds(bool enabled);
}

class IsarSettingsRepository implements SettingsRepository {
  const IsarSettingsRepository(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<AppSettings> load() async {
    return _local.load();
  }

  @override
  AppSettings loadSync() => _local.loadSync();

  @override
  Future<AppSettings> setUseLock(bool enabled) async {
    final AppSettings current = await _local.load();
    final AppSettings next = current.copyWith(useLock: enabled);
    await _local.save(next);
    return next;
  }

  @override
  Future<AppSettings> setFontName(String fontName) async {
    final AppSettings current = await _local.load();
    final AppSettings next = current.copyWith(fontName: fontName);
    await _local.save(next);
    return next;
  }

  @override
  Future<AppSettings> setUseCloudSync(bool enabled) async {
    final AppSettings current = await _local.load();
    final AppSettings next = current.copyWith(useCloudSync: enabled);
    await _local.save(next);
    return next;
  }

  @override
  Future<AppSettings> setUseIcloudSync(bool enabled) async {
    final AppSettings current = await _local.load();
    final AppSettings next = current.copyWith(useIcloudSync: enabled);
    await _local.save(next);
    return next;
  }

  @override
  Future<AppSettings> setBlockRemoteDiaryRestore(bool enabled) async {
    final AppSettings current = await _local.load();
    final AppSettings next = current.copyWith(blockRemoteDiaryRestore: enabled);
    await _local.save(next);
    return next;
  }

  @override
  Future<AppSettings> setRemoveAds(bool enabled) async {
    final AppSettings current = await _local.load();
    final AppSettings next = current.copyWith(removeAds: enabled);
    await _local.save(next);
    return next;
  }
}
