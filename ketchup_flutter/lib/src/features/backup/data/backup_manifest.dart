import 'dart:convert';

/// v2 manifest stored next to `ketchup_data.isar` on Drive.
class BackupManifestV2 {
  BackupManifestV2({
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.files,
  });

  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final Map<String, BackupFileInfo> files;

  static BackupManifestV2 fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawFiles =
        (json['files'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return BackupManifestV2(
      schemaVersion: json['schemaVersion'] as int? ?? 0,
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      appVersion: json['appVersion'] as String? ?? '',
      files: rawFiles.map(
        (String k, dynamic v) => MapEntry(k, BackupFileInfo.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'exportedAt': exportedAt.toUtc().toIso8601String(),
        'appVersion': appVersion,
        'files': files.map((String k, BackupFileInfo v) => MapEntry(k, v.toJson())),
      };

  static String encode(BackupManifestV2 m) => const JsonEncoder.withIndent('  ').convert(m.toJson());
}

class BackupFileInfo {
  BackupFileInfo({required this.sha256, required this.size});

  final String sha256;
  final int size;

  static BackupFileInfo fromJson(Map<String, dynamic> json) {
    return BackupFileInfo(
      sha256: json['sha256'] as String? ?? '',
      size: json['size'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sha256': sha256,
        'size': size,
      };
}
