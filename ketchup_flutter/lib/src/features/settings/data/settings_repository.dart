import 'package:ketchup_flutter/src/features/settings/data/local/settings_local_datasource.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<AppSettings> setUseLock(bool enabled);
  Future<AppSettings> setFontName(String fontName);
  Future<AppSettings> setUseCloudSync(bool enabled);
}

class IsarSettingsRepository implements SettingsRepository {
  const IsarSettingsRepository(this._local);

  final SettingsLocalDataSource _local;

  @override
  Future<AppSettings> load() => _local.load();

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
}
