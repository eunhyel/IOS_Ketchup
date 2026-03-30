class AppSettings {
  const AppSettings({
    required this.useLock,
    required this.fontName,
    this.useCloudSync = false,
    this.useIcloudSync = false,
  });

  final bool useLock;
  final String fontName;

  /// DB 호환용(과거 설정). Firestore 동기화는 Google 로그인 여부만으로 켜지며 이 값과 무관합니다.
  final bool useCloudSync;

  /// iOS CloudKit `FlutterDiaryDay` 업로드·가져오기 (Apple ID, iCloud 용량).
  final bool useIcloudSync;

  AppSettings copyWith({
    bool? useLock,
    String? fontName,
    bool? useCloudSync,
    bool? useIcloudSync,
  }) {
    return AppSettings(
      useLock: useLock ?? this.useLock,
      fontName: fontName ?? this.fontName,
      useCloudSync: useCloudSync ?? this.useCloudSync,
      useIcloudSync: useIcloudSync ?? this.useIcloudSync,
    );
  }
}
