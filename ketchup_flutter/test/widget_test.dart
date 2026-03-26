// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_repository.dart';
import 'package:ketchup_flutter/src/features/diary/domain/diary_entry.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';
import 'package:ketchup_flutter/src/features/settings/data/settings_repository.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

import 'package:ketchup_flutter/src/app.dart';
import 'package:ketchup_flutter/src/core/storage/app_documents.dart';

void main() {
  testWidgets('main screen skeleton renders', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppDocuments.init();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          diaryRepositoryProvider.overrideWithValue(_FakeDiaryRepository()),
          settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        ],
        child: const KetchupApp(),
      ),
    );

    await tester.pumpAndSettle();
    // iOS 메인: 그리드에 일기 날짜(일) 숫자 + 패턴 배경
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });
}

class _FakeDiaryRepository implements DiaryRepository {
  final List<DiaryEntry> _items = <DiaryEntry>[
    DiaryEntry(
      id: 1,
      text: '테스트 데이터',
      date: DateTime(2026, 3, 20),
      defaultImage: 1,
      createdAt: DateTime(2026, 3, 20),
      updatedAt: DateTime(2026, 3, 20),
    ),
  ];

  @override
  Future<DiaryEntry> create({
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) async {
    final DiaryEntry entry = DiaryEntry(
      id: _items.length + 1,
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _items.add(entry);
    return entry;
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((DiaryEntry e) => e.id == id);
  }

  @override
  Future<DiaryEntry?> getById(int id) async {
    for (final DiaryEntry e in _items) {
      if (e.id == id) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<String?> syncKeyIfExists(int localId) async => null;

  @override
  Future<List<DiaryEntry>> fetchAll() async => _items;

  @override
  Future<void> seedIfEmpty() async {}

  @override
  Future<DiaryEntry> update(
    int id, {
    required String text,
    required DateTime date,
    required int defaultImage,
    String? imagePath,
  }) async {
    final int index = _items.indexWhere((DiaryEntry e) => e.id == id);
    final DiaryEntry updated = _items[index].copyWith(
      text: text,
      date: date,
      defaultImage: defaultImage,
      imagePath: imagePath,
      updatedAt: DateTime.now(),
    );
    _items[index] = updated;
    return updated;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings(useLock: false, fontName: 'system', useCloudSync: false);

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<AppSettings> setFontName(String fontName) async {
    _settings = _settings.copyWith(fontName: fontName);
    return _settings;
  }

  @override
  Future<AppSettings> setUseLock(bool enabled) async {
    _settings = _settings.copyWith(useLock: enabled);
    return _settings;
  }

  @override
  Future<AppSettings> setUseCloudSync(bool enabled) async {
    _settings = _settings.copyWith(useCloudSync: enabled);
    return _settings;
  }
}
