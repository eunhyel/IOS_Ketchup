import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const String routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(child: Text('설정 로드 실패: $error')),
        data: (AppSettings settings) => ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
          children: <Widget>[
            const _MenuTile(
              title: 'Firestore 동기화',
              subtitle:
                  '백업 화면에서 Google 로그인만 하면 일기가 Firestore에 자동 동기화됩니다. '
                  '별도 ON 토글은 없습니다. iOS에서 iCloud(CloudKit)는 백업 화면의 동기화 토글을 사용하세요.',
            ),
            _MenuTile(
              title: '암호 설정',
              trailing: Switch(
                value: settings.useLock,
                onChanged: (bool value) => ref.read(appSettingsProvider.notifier).setUseLock(value),
              ),
            ),
            _MenuTile(
              title: '글씨체 변경',
              subtitle: '현재: ${_fontLabel(settings.fontName)}',
              trailing: DropdownButton<String>(
                value: _normalizeFontKey(settings.fontName),
                underline: const SizedBox.shrink(),
                onChanged: (String? value) {
                  if (value != null) {
                    ref.read(appSettingsProvider.notifier).setFontName(value);
                  }
                },
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'font_syong', child: Text('숑숑체')),
                  DropdownMenuItem<String>(value: 'font_hand', child: Text('손글씨체')),
                  DropdownMenuItem<String>(value: 'font_surround', child: Text('서라운드체')),
                  DropdownMenuItem<String>(value: 'font_anemone', child: Text('아네모네에어체')),
                  DropdownMenuItem<String>(value: 'font_nanum', child: Text('나눔스퀘어체')),
                  DropdownMenuItem<String>(value: 'font_ridi', child: Text('리디바탕체')),
                ],
              ),
            ),
            const _MenuTile(title: '백업 및 동기화', chevron: true),
            const _MenuTile(title: '개발자 한마디', chevron: true),
            const _MenuTile(title: '케찹의 역사', chevron: true),
            const _MenuTile(title: '현재 버전', subtitle: '1.1.4'),
          ],
        ),
      ),
    );
  }

  String _normalizeFontKey(String? saved) {
    switch (saved) {
      case 'font_syong':
      case 'font_hand':
      case 'font_surround':
      case 'font_anemone':
      case 'font_nanum':
      case 'font_ridi':
        return saved!;
      case 'serif':
        return 'font_syong';
      case 'sans':
        return 'font_nanum';
      case 'system':
      default:
        return 'font_hand';
    }
  }

  String _fontLabel(String? saved) {
    switch (_normalizeFontKey(saved)) {
      case 'font_syong':
        return '숑숑체';
      case 'font_hand':
        return '손글씨체';
      case 'font_surround':
        return '서라운드체';
      case 'font_anemone':
        return '아네모네에어체';
      case 'font_nanum':
        return '나눔스퀘어체';
      case 'font_ridi':
        return '리디바탕체';
      default:
        return '손글씨체';
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.chevron = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: trailing ?? (chevron ? const Icon(Icons.chevron_right) : null),
      ),
    );
  }
}
