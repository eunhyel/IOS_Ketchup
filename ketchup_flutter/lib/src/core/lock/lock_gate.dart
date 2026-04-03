import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/lock/lock_repository.dart';
import 'package:ketchup_flutter/src/core/lock/password_widgets.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/app_theme.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_ios_text_styles.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    if (_unlocked) {
      return widget.child;
    }

    final AsyncValue<AppSettings> settingsAsync = ref.watch(appSettingsProvider);
    final bool enabled = settingsAsync.valueOrNull?.useLock ?? false;

    if (!enabled) {
      return widget.child;
    }

    return enabled
        ? FutureBuilder<String?>(
            future: ref.read(lockRepositoryProvider).loadPasswordHash(),
            builder: (BuildContext context, AsyncSnapshot<String?> snap) {
              if (snap.connectionState != ConnectionState.done) {
                return widget.child;
              }
              final String? expectedHash = snap.data;
              if (expectedHash == null) {
                // 암호 설정이 없는 경우엔 락을 해제한 것으로 처리합니다.
                return widget.child;
              }
              return Theme(
                // LockGate는 MaterialApp 바깥에 위치하므로, 앱 설정 글꼴을 명시적으로 적용합니다.
                data: AppTheme.light(fontKey: settingsAsync.valueOrNull?.fontName),
                child: _PasswordUnlockOverlay(
                  expectedHash: expectedHash,
                  onUnlocked: () => setState(() => _unlocked = true),
                  onClose: () {
                    // 락 게이트는 기본적으로 닫지 못하게 합니다.
                    // 사용자가 백버튼을 눌러도 그대로 락 상태를 유지합니다.
                  },
                ),
              );
            },
          )
        : widget.child;
  }
}

class _PasswordUnlockOverlay extends ConsumerStatefulWidget {
  const _PasswordUnlockOverlay({
    required this.expectedHash,
    required this.onUnlocked,
    required this.onClose,
  });

  final String expectedHash;
  final VoidCallback onUnlocked;
  final VoidCallback onClose;

  @override
  ConsumerState<_PasswordUnlockOverlay> createState() => _PasswordUnlockOverlayState();
}

class _PasswordUnlockOverlayState extends ConsumerState<_PasswordUnlockOverlay> {
  static const int digitCount = 4;
  String _input = '';
  String _label = '암호 입력';

  @override
  Widget build(BuildContext context) {
    // 해시 함수는 LockRepository와 동일하게 sha256으로 계산합니다.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(KetchupIosAssets.bgPattern),
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              alignment: Alignment.topLeft,
            ),
          ),
          child: SafeArea(
            // iOS `BlurPasswordLoginViewController`: 상단 뒤로가기 없음, Storyboard 수직 스택만 사용
            child: KetchupIosPasswordScene(
              screenWidth: MediaQuery.sizeOf(context).width,
              header: Text(
                _label,
                textAlign: TextAlign.center,
                style: KetchupIosTextStyles.passwordScreenTitle(
                  MediaQuery.sizeOf(context).width / 375.0,
                  fontWeight: ketchupContentWeight(context),
                ),
              ),
              digitCount: digitCount,
              filledCount: _input.length,
              onDigit: _appendDigit,
              onDelete: _backspace,
            ),
          ),
        ),
      ),
    );
  }

  void _appendDigit(int d) {
    if (_input.length >= digitCount) {
      return;
    }
    final String next = '$_input$d';
    setState(() => _input = next);
    if (next.length == digitCount) {
      // 마지막 점(토마토) 색 변화가 보이도록 한 프레임 정도 지연 후 검증.
      Future<void>.delayed(const Duration(milliseconds: 110), () {
        if (!mounted) {
          return;
        }
        if (_input != next || _input.length != digitCount) {
          return;
        }
        _validate();
      });
    }
  }

  void _backspace() {
    if (_input.isEmpty) {
      return;
    }
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _validate() {
    final String attempt = _input;
    final String attemptHash = sha256.convert(utf8.encode(attempt)).toString();
    if (attemptHash == widget.expectedHash) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _input = '';
      _label = '잘못 입력하셨습니다.';
    });

    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() => _label = '암호 입력');
    });
  }
}

