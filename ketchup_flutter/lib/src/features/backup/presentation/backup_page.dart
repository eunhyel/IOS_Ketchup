import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/theme/ketchup_typography_extension.dart';
import 'package:ketchup_flutter/src/core/widgets/ketchup_ios_close_title_row.dart';
import 'package:ketchup_flutter/src/core/dialogs/ketchup_ios_alert_dialog.dart';
import 'package:ketchup_flutter/src/core/platform/icloud_day_sync_bridge.dart';
import 'package:ketchup_flutter/src/core/storage/isar_provider.dart';
import 'package:ketchup_flutter/src/features/backup/data/ketchup_drive_service.dart';
import 'package:ketchup_flutter/src/features/backup/presentation/backup_providers.dart';
import 'package:ketchup_flutter/src/features/diary/data/diary_local_provider.dart';
import 'package:ketchup_flutter/src/features/diary/presentation/diary_providers.dart';
import 'package:ketchup_flutter/src/features/settings/domain/app_settings.dart';
import 'package:ketchup_flutter/src/features/settings/presentation/settings_providers.dart';
import 'package:lottie/lottie.dart';

class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  static const String routeName = '/backup';

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;
  bool _remoteResetRunning = false;
  int _remoteResetBatch = 0;
  int _remoteResetDeleted = 0;
  bool _icloudPushing = false;
  int _icloudPushDone = 0;
  int _icloudPushTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(icloudAccountAvailableProvider);
      unawaited(_trySilentGoogleSignIn());
    });
  }

  /// iOS BackUpView `autoGoogleLogin` / `restorePreviousSignIn` 에 해당.
  Future<void> _trySilentGoogleSignIn() async {
    if (!mounted) {
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        return;
      }
      final GoogleSignIn gs = ref.read(googleSignInProvider);
      final GoogleSignInAccount? account = await gs.signInSilently();
      if (account == null) {
        return;
      }
      final GoogleSignInAuthentication ga = await account.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: ga.accessToken,
        idToken: ga.idToken,
      );
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
    } catch (e, st) {
      debugPrint('Google 자동 로그인 생략/실패(정상일 수 있음): $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<User?> userAsync = ref.watch(firebaseUserProvider);
    final AsyncValue<AppSettings> settingsAsync = ref.watch(appSettingsProvider);
    final bool icloudSync = settingsAsync.valueOrNull?.useIcloudSync ?? false;

    final double w = MediaQuery.sizeOf(context).width;
    final double scale = w / 375.0;

    return PopScope<Object?>(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop && mounted) {
          unawaited(ref.read(diaryEntriesProvider.notifier).load());
        }
      },
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
        child: Stack(
          children: <Widget>[
            SafeArea(
              child: _buildAuthBody(
                userAsync: userAsync,
                scale: scale,
                icloudSync: icloudSync,
              ),
            ),
            if (_busy)
              ColoredBox(
                color: const Color(0x66000000),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Lottie.asset(
                          '${KetchupIosAssets.root}/ani_catchop_loader.json',
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (_icloudPushing && _icloudPushTotal > 0)
                        Padding(
                          padding: EdgeInsets.only(top: 10 * scale),
                          child: Text(
                            '$_icloudPushDone/$_icloudPushTotal',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              color: const Color(0xFFEAEAEA),
                              fontWeight: ketchupContentWeight(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  /// 스트림 첫 이벤트 전에도 [FirebaseAuth.currentUser] 로 UI를 그려 버튼이 먹통처럼 보이지 않게 합니다.
  Widget _buildAuthBody({
    required AsyncValue<User?> userAsync,
    required double scale,
    required bool icloudSync,
  }) {
    final User? fromFirebase =
        Firebase.apps.isEmpty ? null : ref.read(firebaseAuthProvider).currentUser;
    final User? user = userAsync.valueOrNull ?? fromFirebase;

    return userAsync.when(
      loading: () {
        if (user != null) {
          return _buildBackupStack(
            scale: scale,
            user: user,
            icloudSync: icloudSync,
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (Object e, StackTrace st) {
        debugPrint('firebaseUserProvider 오류(레이아웃 표시): $e\n$st');
        return _buildBackupStack(
          scale: scale,
          user: user,
          icloudSync: icloudSync,
        );
      },
      data: (User? u) {
        return _buildBackupStack(
          scale: scale,
          user: u ?? fromFirebase,
          icloudSync: icloudSync,
        );
      },
    );
  }

  Widget _buildBackupStack({
    required double scale,
    required User? user,
    required bool icloudSync,
  }) {
    return Stack(
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: KetchupIosCloseTitleRow(
            scale: scale,
            title: '백업 및 동기화',
            onClose: () => Navigator.of(context).pop(),
          ),
        ),

        // 구글 로그인 버튼 (iOS: imgGoogleDrive)
        Positioned(
          left: 147 * scale,
          top: 90 * scale,
          width: 81 * scale,
          height: 83 * scale,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _busy ? null : () => _onGoogleButtonTap(user),
            child: Image.asset(
              KetchupIosAssets.backupGoogleDrive,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Positioned(
          left: 148.5 * scale,
          top: 187 * scale,
          child: Text(
            user == null ? '구글 로그인' : '구글 로그아웃',
            style: TextStyle(
              fontSize: 17 * scale,
              color: const Color(0xFF303030),
              fontWeight: ketchupContentWeight(context),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 214 * scale,
          child: Text(
            'ID ${user?.email ?? ''}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17 * scale,
              color: const Color(0xFF303030),
              fontWeight: ketchupContentWeight(context),
            ),
          ),
        ),
        Positioned(
          left: 36 * scale,
          top: 350 * scale,
          width: 294 * scale,
          height: 1.0,
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
        // 백업/복원 버튼 (iOS: img-btn-bg)
        Positioned(
          left: 85 * scale,
          top: 260 * scale,
          width: 60 * scale,
          height: 54 * scale,
          child: _ImgBtn(
            title: '백업',
            enabled: !_busy && user != null,
            onTap: user == null ? null : _backup,
          ),
        ),
        Positioned(
          left: 214 * scale,
          top: 260 * scale,
          width: 60 * scale,
          height: 54 * scale,
          child: _ImgBtn(
            title: '복원',
            enabled: !_busy && user != null,
            onTap: user == null ? null : _restore,
          ),
        ),
        // iCloud 동기화는 iOS에서만 노출
        if (Platform.isIOS) ...<Widget>[
          // 아이콘 중심 187.5 * scale — 라벨은 81pt보다 넓어 한 줄로 두기 위해 블록만 넓힙니다.
          Positioned(
            left: 77.5 * scale,
            top: 391.5 * scale,
            width: 220 * scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 83 * scale,
                  width: 81 * scale,
                  child: Opacity(
                    opacity: icloudSync ? 1 : 0.45,
                    child: Image.asset(
                      KetchupIosAssets.backupIcloud,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: (488.5 - 391.5 - 83) * scale),
                Text(
                  'icloud 동기화',
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17 * scale,
                    color: const Color(0xFF303030),
                    fontWeight: ketchupContentWeight(context),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 157.5 * scale,
            top: 534.5 * scale,
            width: 60 * scale,
            height: 54 * scale,
            child: _ToggleBtn(
              text: icloudSync ? 'on' : 'off',
              enabled: !_busy,
              onTap: () {
                unawaited(_onIcloudSyncToggle(current: icloudSync));
              },
            ),
          ),
          if (_remoteResetRunning)
            Positioned(
              left: 0,
              right: 0,
              top: 598 * scale,
              child: Text(
                '원격 삭제 진행중... 배치 $_remoteResetBatch, 누적 $_remoteResetDeleted건',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: const Color(0xFF5C5C5C),
                  fontWeight: ketchupContentWeight(context),
                ),
              ),
            ),
        ],
        if (Platform.isIOS)
          Positioned(
            right: 16 * scale,
            bottom: 8 * scale,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _busy ? null : _resetSyncData,
                borderRadius: BorderRadius.circular(4 * scale),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * scale,
                    vertical: 4 * scale,
                  ),
                  child: Text(
                    '초기화',
                    style: TextStyle(
                      fontSize: 12.5 * scale,
                      height: 1.2,
                      color: _busy
                          ? const Color(0xFF303030).withValues(alpha: 0.38)
                          : const Color(0xFF5C5C5C),
                      decoration: TextDecoration.underline,
                      decorationColor: _busy
                          ? const Color(0xFF303030).withValues(alpha: 0.38)
                          : const Color(0xFF5C5C5C),
                      fontWeight: ketchupContentWeight(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// iOS `iclude_btn` / `cloudStatus` 와 동일: iCloud 불가 시 알림만, 켤 때는 로딩(BackUpView `setData` 대응).
  /// [useIcloudSync]: CloudKit `FlutterDiaryDay` 업로드·가져오기 (Firestore와 별개).
  Future<void> _onIcloudSyncToggle({required bool current}) async {
    if (_busy) {
      return;
    }
    ref.invalidate(icloudAccountAvailableProvider);
    final bool icloudOk = await ref.read(icloudAccountAvailableProvider.future);
    if (!mounted) {
      return;
    }
    if (!icloudOk) {
      await showKetchupIosConfirmDialog(
        context,
        message: 'ICloud를 상태를 확인해주세요.',
        leftText: '아니요',
        rightText: '예',
      );
      return;
    }
    final bool next = !current;
    if (next) {
      setState(() => _busy = true);
      try {
        await ref.read(appSettingsProvider.notifier).setUseIcloudSync(true);
        await () async {
          // 재설치 복원: 로컬이 비어 있을 때만 iCloud에서 채움. 이미 일기가 있으면 전부 CloudKit에 올림.
          final bool hasLocal =
              await ref.read(diaryEntriesProvider.notifier).hasAnyLocalEntries();
          if (!hasLocal) {
            final IcloudHydrationStats stats =
                await ref.read(diaryEntriesProvider.notifier).hydrateFromIcloudWithoutGoogle();
            if (mounted) {
              if (stats.fetchedRows == 0) {
                final Map<String, dynamic> diag = await IcloudDaySyncBridge.debugStatus();
                _toast(
                  'iCloud에서 일기 레코드를 찾지 못했습니다(0건).\n'
                  'Apple ID·iCloud Drive·앱용 iCloud가 켜져 있는지 확인해 주세요.\n'
                  '이후 작성한 일기는 이 토글이 켜져 있으면 CloudKit에도 저장됩니다.\n'
                  'diag: z=${diag['zoneCount']} ch=${diag['changedRecords']} '
                  'ok=${diag['mappableRows']} bad=${diag['nonMappableRecords']}',
                );
                unawaited(ref.read(diaryEntriesProvider.notifier).load());
              } else {
                _toast(
                  'iCloud ${stats.fetchedRows}건 조회 / 반영 ${stats.appliedRows}건\n'
                  '이미지 포함 ${stats.rowsWithImagePayload}건, 원본 이미지 없음 ${stats.rowsWithoutImagePayload}건\n'
                  '이미지 저장 성공 ${stats.imageSavedRows}건, 저장 실패 ${stats.imageSaveFailedRows}건',
                );
              }
            }
          } else {
            // iCloud 동기화(로컬 -> CloudKit 저장) 진행상황 표시
            int lastUiUpdateDone = -999;
            setState(() {
              _icloudPushing = true;
              _icloudPushDone = 0;
              _icloudPushTotal = 0;
            });
            await ref.read(diaryEntriesProvider.notifier).icloudPushAllLocal(
                  onProgress: (int current, int total) {
                    if (!mounted) {
                      return;
                    }
                    if (total <= 0) {
                      return;
                    }
                    // 1건마다 rebuild 하면 부담될 수 있어 5개 단위/마지막에만 갱신합니다.
                    final bool shouldUpdate = current == 0 ||
                        current == total ||
                        (current - lastUiUpdateDone) >= 5;
                    if (!shouldUpdate) {
                      return;
                    }
                    lastUiUpdateDone = current;
                    setState(() {
                      _icloudPushDone = current;
                      _icloudPushTotal = total;
                    });
                  },
                );
            if (mounted) {
              _toast('로컬 일기를 iCloud(CloudKit)에 올렸습니다.');
            }
          }
        }().timeout(
          const Duration(seconds: 600),
          onTimeout: () => throw TimeoutException(
            'iCloud 동기화 준비가 너무 오래 걸립니다. 네트워크·iCloud 상태를 확인한 뒤 다시 시도해 주세요.',
          ),
        );
      } on TimeoutException catch (e) {
        if (mounted) {
          _toast(e.message ?? '시간 초과');
        }
      } on Object catch (e) {
        if (mounted) {
          _toast('iCloud 동기화 설정 중 오류: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _busy = false;
            _icloudPushing = false;
            _icloudPushDone = 0;
            _icloudPushTotal = 0;
          });
        }
      }
    } else {
      await ref.read(appSettingsProvider.notifier).setUseIcloudSync(false);
    }
  }

  Future<void> _resetSyncData() async {
    if (_busy) {
      return;
    }
    final bool? ok = await showKetchupIosConfirmDialog(
      context,
      message: '정말 초기화 시키시겠습니까?',
      leftText: '아니요',
      rightText: '예',
    );
    if (ok != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      // 원격 네트워크 상태에 영향받지 않도록 로컬은 즉시 정리합니다.
      final int localDeleted = await ref.read(diaryLocalDataSourceProvider).clearAllLocalAndMeta();
      await ref.read(appSettingsProvider.notifier).setUseCloudSync(false);
      await ref.read(appSettingsProvider.notifier).setUseIcloudSync(false);

      int icloudDeleted = 0;
      if (Platform.isIOS) {
        icloudDeleted = await IcloudDaySyncBridge.clearDays().timeout(
          const Duration(seconds: 8),
          onTimeout: () => 0,
        );
      }

      ref.invalidate(diaryEntriesProvider);
      _toast('초기화 완료 (로컬 $localDeleted건 / iCloud $icloudDeleted건). 원격 정리는 백그라운드에서 진행합니다.');

      final User? user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        unawaited(_clearRemoteDiaryEntriesInBackground(user.uid));
      }
    } catch (e) {
      _toast('초기화 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _clearRemoteDiaryEntriesInBackground(String uid) async {
    if (mounted) {
      setState(() {
        _remoteResetRunning = true;
        _remoteResetBatch = 0;
        _remoteResetDeleted = 0;
      });
    }
    try {
      final CollectionReference<Map<String, dynamic>> col =
          FirebaseFirestore.instance.collection('users').doc(uid).collection('diary_entries');
      int deleted = 0;
      int batchNo = 0;

      // Firestore 배치는 500개 제한이 있어 페이지 단위로 지웁니다.
      while (true) {
        final QuerySnapshot<Map<String, dynamic>> snap =
            await col.limit(450).get().timeout(const Duration(seconds: 6));
        if (snap.docs.isEmpty) {
          break;
        }
        final WriteBatch batch = FirebaseFirestore.instance.batch();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit().timeout(const Duration(seconds: 6));
        deleted += snap.docs.length;
        batchNo += 1;
        if (mounted) {
          setState(() {
            _remoteResetBatch = batchNo;
            _remoteResetDeleted = deleted;
          });
        }
      }
      if (mounted) {
        _toast('원격 초기화 완료 (클라우드 $deleted건 삭제)');
      }
    } catch (e) {
      if (mounted) {
        _toast('원격 초기화 지연: 네트워크 연결 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _remoteResetRunning = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (Firebase.apps.isEmpty) {
      _toast(
        Platform.isAndroid
            ? 'Firebase가 초기화되지 않았습니다. android/app/google-services.json 을 확인하세요.'
            : 'Firebase가 초기화되지 않았습니다. ios/Ketchup/GoogleService-Info.plist 를 확인하세요.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final GoogleSignIn gs = ref.read(googleSignInProvider);
      // OAuth 브라우저 복귀 URL이 SceneDelegate에서 처리되지 않으면 여기서 영구 대기할 수 있음(타임아웃).
      final GoogleSignInAccount? account = await gs.signIn().timeout(
        const Duration(minutes: 3),
        onTimeout: () => null,
      );
      if (account == null) {
        _toast(
          '로그인이 취소되었거나 응답이 없습니다. '
          'iOS에서 Google 로그인 후 앱으로 돌아오는지 확인하거나, 잠시 후 다시 시도해 주세요.',
        );
        return;
      }
      final GoogleSignInAuthentication ga = await account.authentication;
      if (ga.accessToken == null) {
        _toast('액세스 토큰을 받지 못했습니다. Drive 스코프 동의를 확인하세요.');
        return;
      }
      if (ga.idToken == null) {
        _toast(
          'Firebase용 idToken 이 없습니다. Firebase 콘솔의 웹 클라이언트 ID를 '
          '--dart-define=GOOGLE_WEB_CLIENT_ID=... 로 넘기거나, '
          'ios/Ketchup/GoogleService-Info.plist 에 SERVER_CLIENT_ID(웹 클라이언트 ID)를 추가하세요.',
        );
        return;
      }
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: ga.accessToken,
        idToken: ga.idToken,
      );
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
      if (mounted) {
        _toast('로그인되었습니다.');
      }
    } on FirebaseAuthException catch (e) {
      _toast(
        'Firebase 로그인 실패 (${e.code}): ${e.message ?? e.toString()}\n'
        '웹 클라이언트 ID 설정과 Firebase Console의 Google 로그인 활성화를 확인하세요.',
      );
    } on PlatformException catch (e) {
      final String msg = '${e.code}: ${e.message ?? e.details ?? ''}';
      // Android GoogleSignIn ApiException:10 => SHA-1/패키지 불일치가 거의 대부분
      if (Platform.isAndroid && msg.contains('ApiException: 10')) {
        _toast(
          '안드로이드 Google 로그인 설정 오류입니다(ApiException:10).\n'
          'Firebase 콘솔에 com.O2A.Ketchup의 SHA-1을 등록하고 google-services.json을 다시 받아 교체하세요.',
        );
      } else {
        _toast('로그인 실패: $msg');
      }
    } catch (e) {
      _toast('로그인 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _onGoogleButtonTap(User? user) async {
    if (user == null) {
      await _signIn();
      return;
    }
    await _signOut();
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      final GoogleSignIn gs = ref.read(googleSignInProvider);
      try {
        await gs.disconnect();
      } catch (_) {
        await gs.signOut();
      }
      await ref.read(firebaseAuthProvider).signOut();
      if (mounted) {
        _toast('로그아웃되었습니다.');
      }
    } catch (e) {
      if (mounted) {
        _toast('로그아웃 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// iOS BackUpView `ensureGoogleDriveAuthorized` 와 동일: Drive 스코프가 없으면 추가 동의 요청.
  Future<bool> _ensureDriveScope() async {
    final GoogleSignIn gs = ref.read(googleSignInProvider);
    const List<String> scopes = <String>['https://www.googleapis.com/auth/drive'];

    // 이미 인증된 클라이언트가 있으면 권한이 살아있는 상태로 간주합니다.
    var authClient = await gs.authenticatedClient();
    if (authClient != null) {
      return true;
    }

    await gs.signInSilently();
    authClient = await gs.authenticatedClient();
    if (authClient != null) {
      return true;
    }

    final bool ok = await gs.requestScopes(scopes);
    if (ok) {
      return true;
    }

    // iOS에서 requestScopes 결과가 false여도 실제 토큰이 살아있는 경우가 있어 마지막으로 재확인합니다.
    authClient = await gs.authenticatedClient();
    if (authClient != null) {
      return true;
    }

    if (mounted) {
      _toast('구글 Drive 권한이 필요해요.');
    }
    return false;
  }

  Future<drive.DriveApi?> _driveApi() async {
    final GoogleSignIn gs = ref.read(googleSignInProvider);
    // iOS에서 앱 재시작 후 Google 세션이 복원되지 않으면 authenticatedClient()가 null이 될 수 있어
    // 복원/백업 시점에 조용한 복원 -> 대화형 재인증까지 한 번 더 시도합니다.
    var authClient = await gs.authenticatedClient();
    if (authClient == null) {
      await gs.signInSilently();
      authClient = await gs.authenticatedClient();
    }
    if (authClient == null) {
      final GoogleSignInAccount? account = await gs.signIn().timeout(
        const Duration(minutes: 3),
        onTimeout: () => null,
      );
      if (account != null) {
        authClient = await gs.authenticatedClient();
      }
    }
    if (authClient == null) {
      _toast('Google 세션 복원에 실패했습니다. 다시 로그인 후 시도해 주세요.');
      return null;
    }
    return drive.DriveApi(authClient);
  }

  Future<void> _backup() async {
    if (ref.read(firebaseUserProvider).valueOrNull == null) {
      _toast('먼저 Google 로그인을 해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await _ensureDriveScope()) {
        return;
      }
      final drive.DriveApi? api = await _driveApi();
      if (api == null) {
        return;
      }
      final bytes = await ref.read(isarControllerProvider.notifier).exportCompactedBytes();
      const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.1.4');
      await KetchupDriveService(api).backupIsar(
        isarBytes: bytes,
        appVersion: appVersion,
        currentIsar: ref.read(isarControllerProvider),
      );
      _toast('백업 성공!');
    } catch (e) {
      _toast('백업 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _restore() async {
    if (ref.read(firebaseUserProvider).valueOrNull == null) {
      _toast('먼저 Google 로그인을 해주세요.');
      return;
    }
    final bool? ok = await showKetchupIosConfirmDialog(
      context,
      message: '백업하지 않은 기존 데이터는 덮어쓰일 수 있어요. 복원할까요?',
      leftText: '아니요',
      rightText: '예',
    );
    if (ok != true) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (!await _ensureDriveScope()) {
        return;
      }
      final drive.DriveApi? api = await _driveApi();
      if (api == null) {
        return;
      }
      await KetchupDriveService(api).restoreInto(
        isarController: ref.read(isarControllerProvider.notifier),
        currentIsar: ref.read(isarControllerProvider),
      );
      ref.invalidate(diaryEntriesProvider);
      ref.invalidate(appSettingsProvider);
      if (context.mounted) {
        _toast('복원 성공!');
      }
    } catch (e) {
      final String msg = e.toString();
      if (Platform.isAndroid && msg.contains('default.realm(구 iOS 백업)만')) {
        _toast(
          '복원 실패: Android에서는 구 iOS default.realm만으로 복원할 수 없습니다.\n'
          'iOS에서 먼저 복원 후 새 백업을 만든 뒤 Android에서 복원해 주세요.',
        );
      } else {
        _toast('복원 실패: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _toast(String msg) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _ImgBtn extends StatelessWidget {
  const _ImgBtn({required this.title, required this.enabled, required this.onTap});

  final String title;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(KetchupIosAssets.popupBtnBg),
              fit: BoxFit.contain,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(fontSize: 16, color: const Color(0xFF303030), fontWeight: ketchupContentWeight(context)),
          ),
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.text, required this.enabled, required this.onTap});

  final String text;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(KetchupIosAssets.popupBtnBg),
              fit: BoxFit.contain,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(fontSize: 16, color: const Color(0xFF303030), fontWeight: ketchupContentWeight(context)),
          ),
        ),
      ),
    );
  }
}
