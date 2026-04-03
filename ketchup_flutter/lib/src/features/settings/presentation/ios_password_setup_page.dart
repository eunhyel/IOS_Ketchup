import 'dart:convert';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/lock/lock_repository.dart';
import 'package:ketchup_flutter/src/core/lock/password_widgets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_ios_text_styles.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';

class IosPasswordSetupPage extends ConsumerStatefulWidget {
  const IosPasswordSetupPage({super.key});

  static const String routeName = '/password-setup';

  @override
  ConsumerState<IosPasswordSetupPage> createState() => _IosPasswordSetupPageState();
}

class _IosPasswordSetupPageState extends ConsumerState<IosPasswordSetupPage> {
  static const int digitCount = 4;

  String _input = '';
  String? _firstHash;
  int _step = 0; // 0: 첫 입력, 1: 확인 입력
  String _label = '암호 입력';

  String _hash(String password) => sha256.convert(utf8.encode(password)).toString();

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.sizeOf(context).width;
    final double scale = w / 375.0;
    return Scaffold(
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
          child: Stack(
            children: <Widget>[
              // 설정 진입 시에만 닫기 (앱 잠금 해제 화면과 동일 패턴 배경 + iOS 본문 레이아웃)
              Positioned(
                left: 20,
                top: 10,
                child: IconButton(
                  tooltip: '닫기',
                  style: IconButton.styleFrom(
                    splashFactory: NoSplash.splashFactory,
                  ),
                  icon: Image.asset(
                    KetchupIosAssets.btnHdPrev,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              KetchupIosPasswordScene(
                screenWidth: w,
                header: Text(
                  _label,
                  textAlign: TextAlign.center,
                  style: KetchupIosTextStyles.passwordScreenTitle(scale, fontWeight: ketchupContentWeight(context)),
                ),
                digitCount: digitCount,
                filledCount: _input.length,
                onDigit: _onDigit,
                onDelete: _backspace,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDigit(int d) {
    if (_input.length >= digitCount) {
      return;
    }
    final String next = '$_input$d';
    setState(() => _input = next);
    if (next.length == digitCount) {
      // 마지막 입력 점(토마토) 변화가 보이도록 짧게 지연한 뒤 완료 처리.
      Future<void>.delayed(const Duration(milliseconds: 110), () {
        if (!mounted) {
          return;
        }
        if (_input != next || _input.length != digitCount) {
          return;
        }
        unawaited(_onPasswordComplete(next));
      });
    }
  }

  void _backspace() {
    if (_input.isEmpty) {
      return;
    }
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _onPasswordComplete(String entered) async {
    final String hash = _hash(entered);

    if (_step == 0) {
      setState(() {
        _firstHash = hash;
        _input = '';
        _step = 1;
        _label = '다시한번 입력해주세요';
      });
      return;
    }

    final String? first = _firstHash;
    if (first == null) {
      // 비정상 상태 복구
      setState(() {
        _input = '';
        _step = 0;
        _label = '암호 입력';
      });
      return;
    }

    if (first == hash) {
      try {
        final autoNotifier = ref.read(appSettingsProvider.notifier);
        await ref.read(lockRepositoryProvider).savePassword(entered);
        if (!mounted) {
          return;
        }

        // 중요: useLock을 켜는 순간 LockGate 오버레이가 생기면서
        // 현재 페이지 pop 타이밍과 충돌할 수 있어, 먼저 화면을 닫고 이후에 useLock을 적용합니다.
        Navigator.of(context).pop();
        unawaited(autoNotifier.setUseLock(true));
      } on Object catch (e) {
        if (!mounted) {
          return;
        }
        setState(() {
          _input = '';
          _firstHash = null;
          _step = 0;
          _label = '암호 설정 실패: ${e.toString()}';
        });
      }
      return;
    }

    // 실패: iOS와 유사하게 입력을 초기화
    setState(() {
      _input = '';
      _firstHash = null;
      _step = 0;
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

