import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/core/platform/legacy_realm_bridge.dart';
import 'package:ketchup_flutter/src/core/storage/isar_controller.dart';
import 'package:ketchup_flutter/src/features/backup/data/backup_manifest.dart';
import 'package:ketchup_flutter/src/features/backup/data/legacy_backup_import.dart';

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
    return
        existing.files != null && existing.files!.isNotEmpty ? existing.files!.first.id : null;
  }

  /// Uploads manifest + Isar snapshot. Updates existing files by name (no duplicates).
  Future<void> backupIsar({
    required Uint8List isarBytes,
    required String appVersion,
  }) async {
    final String folderId = await _ensureFolderId();
    final String hash = sha256Hex(isarBytes);
    final BackupManifestV2 manifest = BackupManifestV2(
      schemaVersion: 2,
      exportedAt: DateTime.now().toUtc(),
      appVersion: appVersion,
      files: <String, BackupFileInfo>{
        dataName: BackupFileInfo(sha256: hash, size: isarBytes.length),
      },
    );
    final Uint8List manifestBytes = Uint8List.fromList(utf8.encode(BackupManifestV2.encode(manifest)));

    await _uploadOrUpdate(
      folderId: folderId,
      fileName: manifestName,
      bytes: manifestBytes,
      mimeType: 'application/json',
    );
    await _uploadOrUpdate(
      folderId: folderId,
      fileName: dataName,
      bytes: isarBytes,
      mimeType: 'application/octet-stream',
    );
    // iOS 기존 복원 규칙( Ketchup/default.realm 최신 파일 )과 맞추기 위한 호환 백업
    await _uploadOrUpdate(
      folderId: folderId,
      fileName: legacyRealmName,
      bytes: isarBytes,
      mimeType: 'application/octet-stream',
    );
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
    final String? existingId =
        list.files != null && list.files!.isNotEmpty ? list.files!.first.id : null;
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

    final drive.File? manifestFile = latest[manifestName];
    final drive.File? dataFile = latest[dataName];
    final drive.File? legacyRealmFile = latest[legacyRealmName];
    final drive.File? v1File = latest[legacyV1Name];
    final bool hasV2 = manifestFile?.id != null && dataFile?.id != null;
    final bool hasRealm = legacyRealmFile?.id != null;
    final bool hasV1 = v1File?.id != null;

    final List<String> errors = <String>[];

    // Android는 iOS 구포맷 Realm(`default.realm`)을 직접 파싱할 수 없습니다.
    // (Flutter 최신 백업 포맷: manifest + ketchup_data.isar)
    if (Platform.isAndroid && hasRealm && !hasV2 && !hasV1) {
      throw StateError(
        'Google Drive Ketchup 폴더에 default.realm(구 iOS 백업)만 있어 Android에서 직접 복원할 수 없습니다.\n'
        'iOS에서 먼저 복원 후 앱에서 새 백업을 만들거나, ketchup_data.isar 백업 파일을 사용해 주세요.',
      );
    }

    // iOS 기존 앱 호환: Ketchup/default.realm 최신 파일을 최우선으로 시도
    if (legacyRealmFile?.id != null) {
      final Uint8List realmLikeBytes = await _downloadBytes(legacyRealmFile!.id!);

      // 1) iOS 구버전 Realm 데이터면 네이티브 브리지로 파싱해 이관
      if (Platform.isIOS) {
        try {
          final List<Map<String, dynamic>> rows =
            await LegacyRealmBridge.parseRealmEntries(realmLikeBytes);
          if (rows.isNotEmpty) {
            await LegacyBackupImport.importLegacyRealmEntriesIntoIsar(currentIsar, rows);
            return;
          }
        } catch (e) {
          // default.realm 이 "구 Realm 파일"이 아닌 최신 Isar 바이트일 수 있으므로
          // 파싱 실패를 즉시 치명 오류로 보지 않고 Isar 복원 경로를 계속 시도합니다.
          errors.add('default.realm Realm-bridge 파싱 실패(계속 진행): $e');
        }
      }

      // 2) 최신 앱이 저장한 Isar 스냅샷(default.realm 이름 호환 저장) 복원 시도
      try {
        await isarController.restoreFromVerifiedBytes(realmLikeBytes);
        return;
      } catch (e) {
        errors.add('default.realm Isar 복원 실패: $e');
      }
    }

    // v2 manifest/data 경로
    if (manifestFile?.id != null && dataFile?.id != null) {
      try {
        final Uint8List manifestBytes = await _downloadBytes(manifestFile!.id!);
        final String manifestText = utf8.decode(manifestBytes);
        final BackupManifestV2 manifest = BackupManifestV2.fromJson(
          json.decode(manifestText) as Map<String, dynamic>,
        );
        if (manifest.schemaVersion != 2) {
          throw UnsupportedError('manifest schemaVersion ${manifest.schemaVersion} 은 아직 지원하지 않습니다.');
        }
        final Uint8List dataBytes = await _downloadBytes(dataFile!.id!);
        final BackupFileInfo? expected = manifest.files[dataName];
        if (expected == null) {
          throw StateError('manifest에 $dataName 정보가 없습니다.');
        }
        if (dataBytes.length != expected.size) {
          throw StateError('무결성 오류: 크기 불일치 (expected ${expected.size}, got ${dataBytes.length})');
        }
        final String actualHash = sha256Hex(dataBytes);
        if (actualHash != expected.sha256) {
          throw StateError('무결성 오류: SHA-256 불일치');
        }
        await isarController.restoreFromVerifiedBytes(dataBytes);
        return;
      } catch (e) {
        errors.add('manifest/data 복원 실패: $e');
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
}
