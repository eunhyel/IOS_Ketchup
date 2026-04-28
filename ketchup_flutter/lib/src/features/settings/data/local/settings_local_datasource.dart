import 'package:isar_community/isar.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_bundled_fonts.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/isar_app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

class SettingsLocalDataSource {
  const SettingsLocalDataSource(this._isar);

  final Isar _isar;

  Future<AppSettings> load() async {
    final IsarAppSettings? stored = await _isar.isarAppSettings.get(1);
    if (stored != null) {
      AppSettings domain = stored.toDomain();
      domain = await _migrateLegacyRemoveAdsSwitch(domain);
      return domain;
    }
    await save(AppSettings.emptyDatabaseDefaults);
    return AppSettings.emptyDatabaseDefaults;
  }

  /// [load]와 동일한 규칙으로, Isar에서 **동기** 읽기합니다. 첫 MaterialApp 프레임에 글꼴을 맞추는 데 쓰입니다.
  AppSettings loadSync() {
    final IsarAppSettings? stored = _isar.isarAppSettings.getSync(1);
    if (stored != null) {
      AppSettings domain = stored.toDomain();
      domain = _migrateLegacyRemoveAdsSwitchSync(domain);
      return domain;
    }
    return AppSettings.emptyDatabaseDefaults;
  }

  /// 예전 설정 스위치만으로 `removeAds`가 켜진 경우 — 구독 플래그 없으면 광고 제거로 보지 않습니다.
  Future<AppSettings> _migrateLegacyRemoveAdsSwitch(AppSettings domain) async {
    if (!domain.removeAds || domain.removeAdsSubscriptionActive) {
      return domain;
    }
    final AppSettings cleared = domain.copyWith(removeAds: false);
    await save(cleared);
    return cleared;
  }

  AppSettings _migrateLegacyRemoveAdsSwitchSync(AppSettings domain) {
    if (!domain.removeAds || domain.removeAdsSubscriptionActive) {
      return domain;
    }
    final AppSettings cleared = domain.copyWith(removeAds: false);
    _isar.writeTxnSync(() {
      _isar.isarAppSettings.putSync(IsarAppSettings.fromDomain(cleared));
    });
    return cleared;
  }

  Future<void> save(AppSettings settings) async {
    final IsarAppSettings record = IsarAppSettings.fromDomain(settings);
    await _isar.writeTxn(() async {
      await _isar.isarAppSettings.put(record);
    });
  }

  /// Drive/레거시 복원 후 `system` 등 **번들 키가 아닌** 값은 첫 실행과 같이 숑숑체로 맞춥니다.
  /// 설정에서 고른 `font_hand` 등은 그대로 둡니다.
  /// 백업에 실린 글꼴 대신 **복원 직전** 화면에 쓰이던 글꼴을 유지합니다.
  /// 번들 키가 아니면 숑숑체로 저장합니다.
  Future<void> applyPreservedFontName(String preservedFontKey) async {
    final String key = KetchupBundledFonts.isBundledKey(preservedFontKey)
        ? preservedFontKey
        : 'font_syong';
    final IsarAppSettings? row = await _isar.isarAppSettings.get(1);
    if (row == null) {
      await save(
        AppSettings(
          useLock: false,
          fontName: key,
          useCloudSync: false,
          useIcloudSync: false,
          blockRemoteDiaryRestore: false,
          removeAds: false,
          removeAdsSubscriptionActive: false,
        ),
      );
      return;
    }
    if (row.fontName == key) {
      return;
    }
    await save(row.toDomain().copyWith(fontName: key));
  }

  Future<void> ensureBundledFontOrSyongDefault() async {
    final IsarAppSettings? stored = await _isar.isarAppSettings.get(1);
    if (stored == null) {
      await load();
      return;
    }
    if (KetchupBundledFonts.isBundledKey(stored.fontName)) {
      return;
    }
    await save(stored.toDomain().copyWith(fontName: 'font_syong'));
  }
}
