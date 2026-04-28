class AppSettings {
  const AppSettings({
    required this.useLock,
    required this.fontName,
    this.useCloudSync = false,
    this.useIcloudSync = false,
    this.blockRemoteDiaryRestore = false,
    this.removeAds = false,
    this.removeAdsSubscriptionActive = false,
  });

  /// Isar에 설정 행이 없을 때 [SettingsLocalDataSource.load]가 저장하는 값과 동일합니다.
  /// 첫 프레임 테마(글꼴)에 동기로 쓰입니다.
  static const AppSettings emptyDatabaseDefaults = AppSettings(
    useLock: false,
    fontName: 'font_syong',
    useCloudSync: false,
    useIcloudSync: false,
    blockRemoteDiaryRestore: false,
    removeAds: false,
    removeAdsSubscriptionActive: false,
  );

  final bool useLock;
  final String fontName;

  /// DB 호환용(과거 설정). Firestore 동기화는 Google 로그인 여부만으로 켜지며 이 값과 무관합니다.
  final bool useCloudSync;

  /// iOS CloudKit `FlutterDiaryDay` 업로드·가져오기 (Apple ID, iCloud 용량).
  final bool useIcloudSync;

  /// 백업 화면 「초기화」(로컬만 삭제) 후, 앱 재실행 시에도 Firestore/iCloud로 일기를 다시 채우지 않음. 로그아웃 시 false로 돌림.
  final bool blockRemoteDiaryRestore;

  /// 레거시 스위치·백업 호환용. 광고 숨김은 [removeAdsSubscriptionActive]만 따릅니다.
  final bool removeAds;

  /// 스토어 구독(구매·복원)으로 광고 제거가 켜졌을 때만 true.
  final bool removeAdsSubscriptionActive;

  /// 스토어 구독 활성 — 레거시 `removeAds` 스위치만 켠 경우는 false입니다.
  bool get isSubscribed => removeAdsSubscriptionActive;

  AppSettings copyWith({
    bool? useLock,
    String? fontName,
    bool? useCloudSync,
    bool? useIcloudSync,
    bool? blockRemoteDiaryRestore,
    bool? removeAds,
    bool? removeAdsSubscriptionActive,
  }) {
    return AppSettings(
      useLock: useLock ?? this.useLock,
      fontName: fontName ?? this.fontName,
      useCloudSync: useCloudSync ?? this.useCloudSync,
      useIcloudSync: useIcloudSync ?? this.useIcloudSync,
      blockRemoteDiaryRestore: blockRemoteDiaryRestore ?? this.blockRemoteDiaryRestore,
      removeAds: removeAds ?? this.removeAds,
      removeAdsSubscriptionActive:
          removeAdsSubscriptionActive ?? this.removeAdsSubscriptionActive,
    );
  }
}
