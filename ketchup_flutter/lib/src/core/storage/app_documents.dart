import 'package:path_provider/path_provider.dart';

/// 앱 문서 디렉터리 경로 캐시. [init]은 [main]에서 `runApp` 전에 한 번 호출합니다.
class AppDocuments {
  AppDocuments._();

  static String? _path;

  static Future<void> init() async {
    _path = (await getApplicationDocumentsDirectory()).path;
  }

  static String? get path => _path;
}
