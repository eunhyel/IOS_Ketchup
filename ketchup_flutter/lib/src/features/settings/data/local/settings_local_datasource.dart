import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/isar_app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._isar);

  final Isar _isar;

  Future<AppSettings> load() async {
    final IsarAppSettings? stored = await _isar.isarAppSettings.get(1);
    if (stored != null) {
      return stored.toDomain();
    }
    final AppSettings defaults = const AppSettings(
      useLock: false,
      fontName: 'font_syong',
      useCloudSync: false,
    );
    await save(defaults);
    return defaults;
  }

  Future<void> save(AppSettings settings) async {
    final IsarAppSettings record = IsarAppSettings.fromDomain(settings);
    await _isar.writeTxn(() async {
      await _isar.isarAppSettings.put(record);
    });
  }
}
