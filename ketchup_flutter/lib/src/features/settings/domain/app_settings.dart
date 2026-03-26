class AppSettings {
  const AppSettings({
    required this.useLock,
    required this.fontName,
    this.useCloudSync = false,
  });

  final bool useLock;
  final String fontName;

  /// Android 기본: Firebase(Firestore) 동기화. iOS 네이티브는 iCloud 정책으로 대체 가능.
  final bool useCloudSync;

  AppSettings copyWith({
    bool? useLock,
    String? fontName,
    bool? useCloudSync,
  }) {
    return AppSettings(
      useLock: useLock ?? this.useLock,
      fontName: fontName ?? this.fontName,
      useCloudSync: useCloudSync ?? this.useCloudSync,
    );
  }
}
