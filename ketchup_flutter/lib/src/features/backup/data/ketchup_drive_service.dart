import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/core/platform/legacy_realm_bridge.dart';
import 'package:ketchup_flutter/src/core/storage/isar_controller.dart';
import 'package:ketchup_flutter/src/features/backup/data/backup_manifest.dart';
import 'package:ketchup_flutter/src/features/backup/data/legacy_backup_import.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_image_paths.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_entry.dart';
import 'package:ketchup_flutter/src/features/settings/data/local/settings_local_datasource.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Google Drive operations for the `Ketchup` app folder (parity with iOS `BackUpView`).
class KetchupDriveService {
  KetchupDriveService(this._api);

  final drive.DriveApi _api;

  static const String folderName = 'Ketchup';
  static const String manifestName = 'ketchup_manifest.json';
  static const String dataName = 'ketchup_data.isar';
  // iOS 기존 앱과 파일명 호환용(내용은 Isar 스냅샷 바이트)
  static const String legacyRealmName = 'default.realm';
  static const String legacyV1Name = 'ketchup_backup_v1.json';
  static const String imagesBundleName = 'ketchup_images_bundle.json';
  /// 단일 파일 백업(내부에 manifest / isar / 이미지 번들 포함).
  static const String zipBackupName = 'ketchup_backup.zip';

  static String sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();

  Future<String> _ensureFolderId() async {
    final String? found = await _findFolderId();
    if (found != null && found.isNotEmpty) {
      return found;
    }
    final drive.File created = await _api.files.create(
      drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    return created.id!;
  }

  Future<String?> _findFolderId() async {
    final drive.FileList existing = await _api.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false and 'me' in owners",
      spaces: 'drive',
      pageSize: 10,
      $fields: 'files(id,name)',
    );
    return existing.files != null && existing.files!.isNotEmpty
        ? existing.files!.first.id
        : null;
  }

  /// Uploads manifest + Isar snapshot. Updates existing files by name (no duplicates).
  Future<void> backupIsar({
    required Uint8List isarBytes,
    required String appVersion,
    required Isar currentIsar,
  }) async {
    final String folderId = await _ensureFolderId();
    final String hash = sha256Hex(isarBytes);
    final Uint8List? imagesBundle = await _buildImagesBundleBytes(currentIsar);
    final Map<String, BackupFileInfo> files = <String, BackupFileInfo>{
      dataName: BackupFileInfo(sha256: hash, size: isarBytes.length),
    };
    if (imagesBundle != null && imagesBundle.isNotEmpty) {
      files[imagesBundleName] = BackupFileInfo(
        sha256: sha256Hex(imagesBundle),
        size: imagesBundle.length,
      );
    }

    final BackupManifestV2 manifest = BackupManifestV2(
      schemaVersion: 2,
      exportedAt: DateTime.now().toUtc(),
      appVersion: appVersion,
      files: files,
    );
    final Uint8List manifestBytes = Uint8List.fromList(
      utf8.encode(BackupManifestV2.encode(manifest)),
    );

    final Archive zipArchive = Archive();
    zipArchive.addFile(ArchiveFile.bytes(manifestName, manifestBytes));
    zipArchive.addFile(ArchiveFile.bytes(dataName, isarBytes));
    if (imagesBundle != null && imagesBundle.isNotEmpty) {
      zipArchive.addFile(ArchiveFile.bytes(imagesBundleName, imagesBundle));
    }
    final List<int> zipped = ZipEncoder().encode(zipArchive);
    await _uploadOrUpdate(
      folderId: folderId,
      fileName: zipBackupName,
      bytes: Uint8List.fromList(zipped),
      mimeType: 'application/zip',
    );
    // 예전 포맷(폴더에 파일 3개) 잔여물 제거 — ZIP에 동일 내용이 포함됨.
    try {
      await _deleteDriveFileByNameIfExists(folderId, manifestName);
      await _deleteDriveFileByNameIfExists(folderId, dataName);
      await _deleteDriveFileByNameIfExists(folderId, imagesBundleName);
    } on Object {
      // ignore: Drive 권한/일시 오류 시 백업은 이미 성공한 상태
    }
  }

  Future<void> _deleteDriveFileByNameIfExists(String folderId, String fileName) async {
    final drive.FileList list = await _api.files.list(
      q: "'$folderId' in parents and name='$fileName' and trashed=false",
      spaces: 'drive',
      pageSize: 2,
      $fields: 'files(id,name)',
    );
    final String? id = list.files != null && list.files!.isNotEmpty
        ? list.files!.first.id
        : null;
    if (id != null && id.isNotEmpty) {
      await _api.files.delete(id);
    }
  }

  Future<void> _uploadOrUpdate({
    required String folderId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final drive.FileList list = await _api.files.list(
      q: "'$folderId' in parents and name='$fileName' and trashed=false",
      spaces: 'drive',
      pageSize: 2,
      $fields: 'files(id,name)',
    );
    final String? existingId = list.files != null && list.files!.isNotEmpty
        ? list.files!.first.id
        : null;
    final drive.Media media = drive.Media(
      Stream<List<int>>.value(bytes),
      bytes.length,
    );
    if (existingId != null) {
      await _api.files.update(
        drive.File()..name = fileName,
        existingId,
        uploadMedia: media,
      );
    } else {
      await _api.files.create(
        drive.File()
          ..name = fileName
          ..parents = <String>[folderId],
        uploadMedia: media,
      );
    }
  }

  /// Restores from Drive with integrity checks, rollback on failure.
  Future<void> restoreInto({
    required IsarController isarController,
    required Isar currentIsar,
  }) async {
    final String? folderId = await _findFolderId();
    if (folderId == null || folderId.isEmpty) {
      throw StateError('Google Drive에 Ketchup 폴더가 없어 복원할 수 없습니다.');
    }
    final Map<String, drive.File> latest = await _listLatestByName(folderId);

    final drive.File? zipFile = latest[zipBackupName];
    final drive.File? manifestFile = latest[manifestName];
    final drive.File? dataFile = latest[dataName];
    final drive.File? legacyRealmFile = latest[legacyRealmName];
    final drive.File? v1File = latest[legacyV1Name];
    final bool hasZip = zipFile?.id != null;
    final bool hasV2 = manifestFile?.id != null && dataFile?.id != null;
    final bool hasRealm = legacyRealmFile?.id != null;
    final bool hasV1 = v1File?.id != null;

    final List<String> errors = <String>[];
    final String preservedFontKey = (await SettingsLocalDataSource(
      currentIsar,
    ).load()).fontName;

    // Android는 iOS 구포맷 Realm(`default.realm`)을 직접 파싱할 수 없습니다.
    // (Flutter 최신 백업 포맷: manifest + ketchup_data.isar)
    if (Platform.isAndroid && hasRealm && !hasV2 && !hasV1 && !hasZip) {
      throw StateError(
        'Google Drive Ketchup 폴더에 default.realm(구 iOS 백업)만 있어 Android에서 직접 복원할 수 없습니다.\n'
        'iOS에서 먼저 복원 후 앱에서 새 백업을 만들거나, ketchup_data.isar 백업 파일을 사용해 주세요.',
      );
    }

    // ZIP 단일 파일(최신) 우선
    if (hasZip) {
      try {
        final Uint8List zipBytes = await _downloadBytes(zipFile!.id!);
        final Archive archive = ZipDecoder().decodeBytes(zipBytes);
        final Uint8List? manifestBytes = _readZipEntryBytes(archive, manifestName);
        final Uint8List? dataBytes = _readZipEntryBytes(archive, dataName);
        if (manifestBytes == null || dataBytes == null) {
          throw StateError('ZIP에 $manifestName 또는 $dataName 이 없습니다.');
        }
        final String manifestText = utf8.decode(manifestBytes);
        final BackupManifestV2 manifest = BackupManifestV2.fromJson(
          json.decode(manifestText) as Map<String, dynamic>,
        );
        if (manifest.schemaVersion != 2) {
          throw UnsupportedError(
            'manifest schemaVersion ${manifest.schemaVersion} 은 아직 지원하지 않습니다.',
          );
        }
        final BackupFileInfo? expected = manifest.files[dataName];
        if (expected == null) {
          throw StateError('manifest에 $dataName 정보가 없습니다.');
        }
        if (dataBytes.length != expected.size) {
          throw StateError(
            '무결성 오류: 크기 불일치 (expected ${expected.size}, got ${dataBytes.length})',
          );
        }
        final String actualHash = sha256Hex(dataBytes);
        if (actualHash != expected.sha256) {
          throw StateError('무결성 오류: SHA-256 불일치');
        }
        await isarController.restoreFromVerifiedBytes(
          dataBytes,
          afterOpen: (Isar isar) => _applyPreservedFont(isar, preservedFontKey),
        );
        final Uint8List? bundleFromZip = _readZipEntryBytes(archive, imagesBundleName);
        await _restoreImagesBundleFromBytes(bundleFromZip);
        await _repairImagePathsAfterRestore(isarController.currentIsar);
        return;
      } catch (e) {
        errors.add('ZIP 백업 복원 실패: $e');
      }
    }

    // v2 manifest/data 경로(구 포맷: 폴더에 파일 3개) — ZIP 실패 시
    if (manifestFile?.id != null && dataFile?.id != null) {
      try {
        final Uint8List manifestBytes = await _downloadBytes(manifestFile!.id!);
        final String manifestText = utf8.decode(manifestBytes);
        final BackupManifestV2 manifest = BackupManifestV2.fromJson(
          json.decode(manifestText) as Map<String, dynamic>,
        );
        if (manifest.schemaVersion != 2) {
          throw UnsupportedError(
            'manifest schemaVersion ${manifest.schemaVersion} 은 아직 지원하지 않습니다.',
          );
        }
        final Uint8List dataBytes = await _downloadBytes(dataFile!.id!);
        final BackupFileInfo? expected = manifest.files[dataName];
        if (expected == null) {
          throw StateError('manifest에 $dataName 정보가 없습니다.');
        }
        if (dataBytes.length != expected.size) {
          throw StateError(
            '무결성 오류: 크기 불일치 (expected ${expected.size}, got ${dataBytes.length})',
          );
        }
        final String actualHash = sha256Hex(dataBytes);
        if (actualHash != expected.sha256) {
          throw StateError('무결성 오류: SHA-256 불일치');
        }
        await isarController.restoreFromVerifiedBytes(
          dataBytes,
          afterOpen: (Isar isar) => _applyPreservedFont(isar, preservedFontKey),
        );
        await _restoreImagesBundleIfAny(latest);
        await _repairImagePathsAfterRestore(isarController.currentIsar);
        return;
      } catch (e) {
        errors.add('manifest/data 복원 실패: $e');
      }
    }

    // 레거시 호환: v2가 없거나 실패한 경우 default.realm 시도
    if (legacyRealmFile?.id != null) {
      final Uint8List realmLikeBytes = await _downloadBytes(
        legacyRealmFile!.id!,
      );

      // 1) iOS 구버전 Realm 데이터면 네이티브 브리지로 파싱해 이관
      if (Platform.isIOS) {
        try {
          final List<Map<String, dynamic>> rows =
              await LegacyRealmBridge.parseRealmEntries(realmLikeBytes);
          if (rows.isNotEmpty) {
            await LegacyBackupImport.importLegacyRealmEntriesIntoIsar(
              currentIsar,
              rows,
            );
            await _applyPreservedFont(currentIsar, preservedFontKey);
            await _restoreImagesBundleIfAny(latest);
            await _repairImagePathsAfterRestore(currentIsar);
            return;
          }
        } catch (e) {
          errors.add('default.realm Realm-bridge 파싱 실패(계속 진행): $e');
        }
      }

      // 2) 일부 과거 버전이 default.realm 이름으로 Isar 바이트를 올린 경우도 호환
      try {
        await isarController.restoreFromVerifiedBytes(
          realmLikeBytes,
          afterOpen: (Isar isar) => _applyPreservedFont(isar, preservedFontKey),
        );
        await _restoreImagesBundleIfAny(latest);
        await _repairImagePathsAfterRestore(isarController.currentIsar);
        return;
      } catch (e) {
        errors.add('default.realm Isar 복원 실패: $e');
      }
    }

    // 구버전 JSON(v1) 경로
    if (v1File?.id != null) {
      try {
        final Uint8List v1bytes = await _downloadBytes(v1File!.id!);
        final String jsonText = utf8.decode(v1bytes);
        if (!LegacyBackupImport.looksLikeV1(jsonText)) {
          throw FormatException('구버전 JSON 형식이 아닙니다.');
        }
        final Uint8List rollback = await isarController.exportCompactedBytes();
        try {
          await LegacyBackupImport.importV1JsonIntoIsar(currentIsar, jsonText);
        } catch (e) {
          await isarController.restoreFromVerifiedBytes(rollback);
          rethrow;
        }
        await _applyPreservedFont(currentIsar, preservedFontKey);
        return;
      } catch (e) {
        errors.add('v1 JSON 복원 실패: $e');
      }
    }

    if (errors.isNotEmpty) {
      throw StateError(
        'Google Drive에서 데이터를 복원하지 못했습니다.\n\n${errors.join('\n\n')}',
      );
    }
    throw StateError('Ketchup 폴더에 복원할 백업 파일이 없습니다.');
  }

  Future<Map<String, drive.File>> _listLatestByName(String folderId) async {
    final drive.FileList list = await _api.files.list(
      q: "'$folderId' in parents and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
      pageSize: 100,
      $fields: 'files(id,name,modifiedTime,mimeType,size)',
    );
    final Map<String, drive.File> out = <String, drive.File>{};
    for (final drive.File? f in list.files ?? <drive.File>[]) {
      if (f?.name == null) {
        continue;
      }
      out.putIfAbsent(f!.name!, () => f);
    }
    return out;
  }

  Future<Uint8List> _downloadBytes(String fileId) async {
    final Object media = await _api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );
    if (media is! drive.Media) {
      throw StateError('Drive 다운로드 응답 형식 오류');
    }
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<Uint8List?> _buildImagesBundleBytes(Isar currentIsar) async {
    try {
      final Directory doc = await getApplicationDocumentsDirectory();
      final Directory imgDir = Directory(p.join(doc.path, 'ketchup_images'));
      final Map<String, String> files = <String, String>{};
      if (await imgDir.exists()) {
        final List<FileSystemEntity> entities = await imgDir.list().toList();
        for (final FileSystemEntity e in entities) {
          if (e is! File) {
            continue;
          }
          final String name = p.basename(e.path);
          final List<int> bytes = await e.readAsBytes();
          if (bytes.isEmpty) {
            continue;
          }
          files[name] = base64Encode(bytes);
        }
      }

      // 폴더 스캔에 누락된 이미지가 있어도(경로 이전/이름 변경 등),
      // 실제 Isar 레코드가 참조하는 파일을 추가로 번들링합니다.
      final List<IsarDiaryEntry> rows = await currentIsar.isarDiaryEntrys.where().findAll();
      for (final IsarDiaryEntry row in rows) {
        final String? raw = row.imagePath;
        if (raw == null || raw.trim().isEmpty) {
          continue;
        }
        final String? resolved = DiaryImagePaths.resolveDisplay(raw);
        if (resolved == null || resolved.isEmpty) {
          continue;
        }
        final File f = File(resolved);
        if (!await f.exists()) {
          continue;
        }
        final String name = p.basename(f.path);
        if (files.containsKey(name)) {
          continue;
        }
        final List<int> bytes = await f.readAsBytes();
        if (bytes.isEmpty) {
          continue;
        }
        files[name] = base64Encode(bytes);
      }
      if (files.isEmpty) {
        return null;
      }
      final Map<String, dynamic> root = <String, dynamic>{
        'schemaVersion': 1,
        'files': files,
      };
      return Uint8List.fromList(utf8.encode(json.encode(root)));
    } on Object {
      return null;
    }
  }

  Uint8List? _readZipEntryBytes(Archive archive, String baseName) {
    for (final ArchiveFile f in archive.files) {
      if (!f.isFile) {
        continue;
      }
      if (f.name == baseName || p.basename(f.name) == baseName) {
        return f.content;
      }
    }
    return null;
  }

  Future<void> _restoreImagesBundleIfAny(Map<String, drive.File> latest) async {
    final drive.File? bundleFile = latest[imagesBundleName];
    if (bundleFile?.id == null) {
      return;
    }
    final Uint8List bytes = await _downloadBytes(bundleFile!.id!);
    await _restoreImagesBundleFromBytes(bytes);
  }

  Future<void> _restoreImagesBundleFromBytes(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      return;
    }
    final Map<String, dynamic> root =
        json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    final Map<String, dynamic> files =
        (root['files'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    if (files.isEmpty) {
      return;
    }

    final Directory doc = await getApplicationDocumentsDirectory();
    final Directory imgDir = Directory(p.join(doc.path, 'ketchup_images'));
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    for (final MapEntry<String, dynamic> entry in files.entries) {
      final String name = entry.key;
      final String? b64 = entry.value as String?;
      if (b64 == null || b64.isEmpty) {
        continue;
      }
      final File out = File(p.join(imgDir.path, name));
      await out.writeAsBytes(base64Decode(b64), flush: true);
    }
  }

  Future<void> _applyPreservedFont(Isar isar, String preservedFontKey) async {
    await SettingsLocalDataSource(
      isar,
    ).applyPreservedFontName(preservedFontKey);
  }

  Future<void> _repairImagePathsAfterRestore(Isar isar) async {
    final Directory doc = await getApplicationDocumentsDirectory();
    final Directory imgDir = Directory(p.join(doc.path, 'ketchup_images'));
    if (!await imgDir.exists()) {
      return;
    }
    final List<IsarDiaryEntry> entries = await isar.isarDiaryEntrys
        .where()
        .findAll();
    if (entries.isEmpty) {
      return;
    }

    int repaired = 0;
    await isar.writeTxn(() async {
      for (final IsarDiaryEntry row in entries) {
        final String? stored = row.imagePath;
        if (stored == null || stored.isEmpty) {
          continue;
        }

        final File direct = File(stored);
        if (await direct.exists()) {
          continue;
        }

        final File rel = File(p.join(doc.path, stored));
        if (await rel.exists()) {
          row.imagePath = p.relative(rel.path, from: doc.path);
          await isar.isarDiaryEntrys.put(row);
          repaired += 1;
          continue;
        }

        final File byName = File(p.join(imgDir.path, p.basename(stored)));
        if (await byName.exists()) {
          row.imagePath = p.relative(byName.path, from: doc.path);
          await isar.isarDiaryEntrys.put(row);
          repaired += 1;
        }
      }
    });
    if (repaired > 0) {
      // ignore: avoid_print
      print('[backup] repaired image paths: $repaired');
    }
  }
}
