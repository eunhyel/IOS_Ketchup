class AppSettings {
  const AppSettings({
    required this.useLock,
    required this.fontName,
    this.useCloudSync = false,
    this.useIcloudSync = false,
    this.blockRemoteDiaryRestore = false,
    this.removeAds = false,
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
  );

  final bool useLock;
  final String fontName;

  /// DB 호환용(과거 설정). Firestore 동기화는 Google 로그인 여부만으로 켜지며 이 값과 무관합니다.
  final bool useCloudSync;

  /// iOS CloudKit `FlutterDiaryDay` 업로드·가져오기 (Apple ID, iCloud 용량).
  final bool useIcloudSync;

  /// 백업 화면 「초기화」(로컬만 삭제) 후, 앱 재실행 시에도 Firestore/iCloud로 일기를 다시 채우지 않음. 로그아웃 시 false로 돌림.
  final bool blockRemoteDiaryRestore;

  /// true이면 배너 광고를 끕니다.
  final bool removeAds;

  /// 구독(또는 광고 제거 구매) 활성 여부 — [removeAds]와 동일합니다.
  bool get isSubscribed => removeAds;

  AppSettings copyWith({
    bool? useLock,
    String? fontName,
    bool? useCloudSync,
    bool? useIcloudSync,
    bool? blockRemoteDiaryRestore,
    bool? removeAds,
  }) {
    return AppSettings(
      useLock: useLock ?? this.useLock,
      fontName: fontName ?? this.fontName,
      useCloudSync: useCloudSync ?? this.useCloudSync,
      useIcloudSync: useIcloudSync ?? this.useIcloudSync,
      blockRemoteDiaryRestore: blockRemoteDiaryRestore ?? this.blockRemoteDiaryRestore,
      removeAds: removeAds ?? this.removeAds,
    );
  }
}
