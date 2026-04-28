import 'package:isar_community/isar.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';

part 'isar_app_settings.g.dart';

@collection
class IsarAppSettings {
  Id id = 1;
  late bool useLock;
  late String fontName;

  /// 기존 DB 호환: 없으면 null → false.
  bool? useCloudSync;

  /// 기존 DB 호환: 없으면 null → false.
  bool? useIcloudSync;

  /// 기존 DB 호환: 없으면 null → false.
  bool? blockRemoteDiaryRestore;

  /// 기존 DB 호환: 없으면 null → false.
  bool? removeAds;

  /// 스토어 구독으로만 true. 없으면 null → false.
  bool? removeAdsSubscriptionActive;

  AppSettings toDomain() => AppSettings(
        useLock: useLock,
        fontName: fontName,
        useCloudSync: useCloudSync ?? false,
        useIcloudSync: useIcloudSync ?? false,
        blockRemoteDiaryRestore: blockRemoteDiaryRestore ?? false,
        removeAds: removeAds ?? false,
        removeAdsSubscriptionActive: removeAdsSubscriptionActive ?? false,
      );

  static IsarAppSettings fromDomain(AppSettings settings) {
    return IsarAppSettings()
      ..id = 1
      ..useLock = settings.useLock
      ..fontName = settings.fontName
      ..useCloudSync = settings.useCloudSync
      ..useIcloudSync = settings.useIcloudSync
      ..blockRemoteDiaryRestore = settings.blockRemoteDiaryRestore
      ..removeAds = settings.removeAds
      ..removeAdsSubscriptionActive = settings.removeAdsSubscriptionActive;
  }
}
