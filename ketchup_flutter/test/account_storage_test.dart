import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketchup_flutter/src/core/storage/app_documents.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/write_draft_storage.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('account_test');
    await AppDocuments.init(root: root);
    await AppDocuments.selectAccount(null);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test(
    'guest and two accounts retain independent drafts and image folders',
    () async {
      final paths = <String>{};
      for (final uid in <String?>[null, 'account-a', 'account-b']) {
        await AppDocuments.selectAccount(uid);
        paths.add(AppDocuments.path!);
        await WriteDraftStorage.save(
          text: uid ?? 'guest',
          date: DateTime(2026),
          defaultImage: 0,
          iosPlaceholderActive: false,
        );
        await File(
          '${AppDocuments.path}/photo.jpg',
        ).writeAsString(uid ?? 'guest');
      }
      expect(paths.length, 3);
      for (final uid in <String?>['account-a', null, 'account-b']) {
        await AppDocuments.selectAccount(uid);
        expect((await WriteDraftStorage.load())!.text, uid ?? 'guest');
        expect(
          await File('${AppDocuments.path}/photo.jpg').readAsString(),
          uid ?? 'guest',
        );
      }
      expect(
        await File('${root.path}/ketchup_compose_draft.json').exists(),
        isTrue,
      );
    },
  );
  test('account names are stable and cannot escape the account directory', () {
    expect(AppDocuments.scopeName('a/../../b'), isNot(contains('/')));
    expect(AppDocuments.scopeName('a'), AppDocuments.scopeName('a'));
    expect(AppDocuments.scopeName('a'), isNot(AppDocuments.scopeName('b')));
    expect(AppDocuments.scopeName(null), 'ketchup');
  });
}
