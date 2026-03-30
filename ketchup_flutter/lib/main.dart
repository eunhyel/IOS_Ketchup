import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ketchup_flutter/src/app.dart';
import 'package:ketchup_flutter/src/core/assets/ketchup_ios_assets.dart';
import 'package:ketchup_flutter/src/core/lock/lock_gate.dart';
import 'package:ketchup_flutter/src/core/storage/app_documents.dart';
import 'package:ketchup_flutter/src/core/storage/app_isar.dart';
import 'package:ketchup_flutter/src/core/storage/isar_controller.dart';
import 'package:ketchup_flutter/src/core/storage/isar_provider.dart';
import 'package:ketchup_flutter/src/features/sync/presentation/sync_host.dart';

Future<void> main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  // 네이티브 스플래시(Storyboard)가 Flutter 첫 프레임까지 유지되도록 두고, 초기화 후 제거합니다.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const _BootstrapApp());
}

/// 무거운 초기화(Firebase/Isar)를 첫 프레임 뒤로 미뤄 스플래시 체감 시간을 줄입니다.
class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  Isar? _isar;
  bool _firebaseOk = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await AppDocuments.init();
      bool firebaseOk = false;
      try {
        await Firebase.initializeApp();
        firebaseOk = true;
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e, st) {
        debugPrint('Firebase.initializeApp 실패(google-services 등 확인): $e $st');
      }
      final Isar isar = await AppIsar.open();
      if (!mounted) {
        return;
      }
      setState(() {
        _firebaseOk = firebaseOk;
        _isar = isar;
      });
    } catch (e, st) {
      debugPrint('앱 초기화 실패(Isar 등): $e $st');
    } finally {
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Isar? isar = _isar;
    if (isar == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _BootstrapLoadingScreen(),
      );
    }
    return ProviderScope(
      overrides: <Override>[
        isarControllerProvider.overrideWith((Ref ref) => IsarController(isar)),
      ],
      child: LockGate(
        // iCloud-only 동기화는 Firebase 초기화와 무관하게 동작해야 하므로 SyncHost는 항상 유지합니다.
        child: const SyncHost(child: KetchupApp()),
      ),
    );
  }
}

class _BootstrapLoadingScreen extends StatelessWidget {
  const _BootstrapLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(KetchupIosAssets.bgPattern),
          repeat: ImageRepeat.repeat,
          fit: BoxFit.none,
          alignment: Alignment.topLeft,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF5C5C5C)),
      ),
    );
  }
}
