import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/core/storage/isar_controller.dart';

/// Override in `main()` with the opened instance.
final StateNotifierProvider<IsarController, Isar> isarControllerProvider =
    StateNotifierProvider<IsarController, Isar>(
  (Ref ref) => throw UnimplementedError('Override isarControllerProvider from main()'),
);

final Provider<Isar> isarProvider = Provider<Isar>(
  (Ref ref) => ref.watch(isarControllerProvider),
);
