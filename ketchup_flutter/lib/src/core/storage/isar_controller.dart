import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/core/storage/app_isar.dart';
import 'package:ketchup_flutter/src/features/diary/data/local/isar_diary_entry.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Holds the active [Isar] instance and supports safe restore with rollback.
class IsarController extends StateNotifier<Isar> {
  IsarController(super.initial);

  /// Exports a compacted snapshot (safe while DB is open).
  Future<Uint8List> exportCompactedBytes() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String tmpPath = p.join(dir.path, 'ketchup_export_${DateTime.now().millisecondsSinceEpoch}.isar');
    final File tmp = File(tmpPath);
    try {
      await state.copyToFile(tmpPath);
      return await tmp.readAsBytes();
    } finally {
      if (await tmp.exists()) {
        await tmp.delete();
      }
    }
  }

  /// Replaces `ketchup.isar` with [bytes] after verification.
  /// Rolls back the DB file on failure, then rethrows.
  Future<void> restoreFromVerifiedBytes(Uint8List bytes) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String mainPath = p.join(dir.path, AppIsar.fileName);
    final String rollbackPath = p.join(dir.path, '${AppIsar.fileName}.rollback');
    final File mainFile = File(mainPath);
    final File rollbackFile = File(rollbackPath);

    await state.close();

    try {
      if (await mainFile.exists()) {
        await mainFile.copy(rollbackPath);
      } else if (await rollbackFile.exists()) {
        await rollbackFile.delete();
      }

      await mainFile.writeAsBytes(bytes, flush: true);

      final Isar reopened = await AppIsar.open();
      await reopened.txn(() async {
        await reopened.isarDiaryEntrys.count();
      });
      state = reopened;
    } catch (e, st) {
      debugPrint('restoreFromVerifiedBytes failed: $e\n$st');
      try {
        if (await rollbackFile.exists()) {
          await rollbackFile.copy(mainPath);
        }
      } catch (copyErr) {
        debugPrint('rollback copy failed: $copyErr');
      }
      state = await AppIsar.open();
      rethrow;
    } finally {
      if (await rollbackFile.exists()) {
        try {
          await rollbackFile.delete();
        } catch (_) {}
      }
    }
  }
}
