import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// iOS: 네이티브 `Write+func.instreamGo` 와 동일 (`instagram-stories://share` + UIPasteboard).
/// Android: 시스템 공유 시트로 이미지 전달(인스타 선택 가능).
class InstagramStoryShare {
  InstagramStoryShare._();

  static const MethodChannel _channel = MethodChannel('com.o2a.ketchup/instagram_story');

  /// [pngBytes] PNG 바이트(스티커). iOS 네이티브에서 JPEG 로 변환 후 붙여넣기합니다.
  static Future<bool> shareDiaryCardAsStory(Uint8List pngBytes) async {
    if (Platform.isIOS) {
      try {
        final bool? ok = await _channel.invokeMethod<bool>(
          'shareInstagramStorySticker',
          <String, dynamic>{'png': pngBytes},
        );
        return ok ?? false;
      } on PlatformException catch (e) {
        if (e.code == 'missing_facebook_app_id') {
          throw MissingFacebookAppIdException(e.message ?? e.code);
        }
        rethrow;
      }
    }
    if (Platform.isAndroid) {
      try {
        final Directory dir = await getTemporaryDirectory();
        final File f = File(
          '${dir.path}/ketchup_story_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await f.writeAsBytes(pngBytes);
        await Share.shareXFiles(<XFile>[XFile(f.path)]);
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

/// iOS `Info.plist`의 `FacebookAppID` 미설정 (Meta 스토리 공유 필수).
class MissingFacebookAppIdException implements Exception {
  MissingFacebookAppIdException(this.message);
  final String message;

  @override
  String toString() => message;
}
