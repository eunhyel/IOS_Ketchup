import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketchup_flutter/src/features/backup/data/ketchup_drive_service.dart';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('backup_test');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });
  test('missing or empty referenced image rejects backup', () async {
    final path = '${dir.path}/photo.jpg';
    await expectLater(
      KetchupDriveService.buildImagesBundleForPaths({1: path}),
      throwsStateError,
    );
    await File(path).writeAsBytes([]);
    await expectLater(
      KetchupDriveService.buildImagesBundleForPaths({1: path}),
      throwsStateError,
    );
  });
  test('image-free diaries need no bundle', () async {
    expect(
      await KetchupDriveService.buildImagesBundleForPaths({1: null}),
      isNull,
    );
  });
  test('referenced image bytes survive bundle encoding', () async {
    final file = await File('${dir.path}/photo.jpg').writeAsBytes([1, 2, 3]);
    final bytes = await KetchupDriveService.buildImagesBundleForPaths({
      1: file.path,
    });
    final bundle = jsonDecode(utf8.decode(bytes!));
    expect(base64Decode(bundle['files']['photo.jpg'] as String), [1, 2, 3]);
  });
  test('same filenames with different contents reject backup', () async {
    final sub = await Directory('${dir.path}/sub').create();
    final a = await File('${dir.path}/photo.jpg').writeAsBytes([1]);
    final b = await File('${sub.path}/photo.jpg').writeAsBytes([2]);
    await expectLater(
      KetchupDriveService.buildImagesBundleForPaths({1: a.path, 2: b.path}),
      throwsStateError,
    );
  });
}
