import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/theme/app_theme.dart';
import 'package:ketchup_flutter/src/features/backup/presentation/backup_page.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_list_page.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/write_edit_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_font_picker_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_one_talk_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/ios_password_setup_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_page.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

class KetchupApp extends ConsumerWidget {
  const KetchupApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    return MaterialApp(
      title: 'Ketchup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(fontKey: settings?.fontName),
      initialRoute: DiaryListPage.routeName,
      routes: <String, WidgetBuilder>{
        DiaryListPage.routeName: (_) => const DiaryListPage(),
        SettingsPage.routeName: (_) => const SettingsPage(),
        BackupPage.routeName: (_) => const BackupPage(),
        IosPasswordSetupPage.routeName: (_) => const IosPasswordSetupPage(),
        IosFontPickerPage.routeName: (_) => const IosFontPickerPage(),
        IosOneTalkPage.routeName: (_) => const IosOneTalkPage(),
      },
      onGenerateRoute: (RouteSettings settings) {
        if (settings.name == WriteEditPage.routeName) {
          final WriteEditArgs args =
              (settings.arguments as WriteEditArgs?) ?? const WriteEditArgs.create();
          return MaterialPageRoute<void>(
            builder: (_) => WriteEditPage(args: args),
          );
        }
        return null;
      },
    );
  }
}
