import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/storage/isar_provider.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/diary_local_datasource.dart';

final Provider<DiaryLocalDataSource> diaryLocalDataSourceProvider = Provider<DiaryLocalDataSource>(
  (Ref ref) => DiaryLocalDataSource(ref.watch(isarProvider)),
);
