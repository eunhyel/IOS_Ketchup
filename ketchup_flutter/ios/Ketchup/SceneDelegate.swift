import CloudKit
import Flutter
import GoogleSignIn
import RealmSwift
import UIKit

private enum FlutterNativeChannelsSetup {
  static var done = false
}

/// Meta(Instagram) 스토리 스티커 공유: 2023년 이후 반드시
/// `instagram-stories://share?source_application=<Facebook App ID>` + UIPasteboard 조합.
/// App ID 없이 `instagram-stories://share` 만 열면 인스타만 켜지고 스토리 컴포저에 이미지가 안 붙습니다.
/// https://developers.facebook.com/docs/instagram-platform/sharing-to-stories
private enum InstagramStoryShare {
  static func facebookAppIdFromPlist() -> String? {
    let raw = (Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return raw.isEmpty ? nil : raw
  }

  /// Meta 공식 샘플과 동일한 URL (쿼리 필수).
  static func storiesShareURL(appId: String) -> URL? {
    var c = URLComponents()
    c.scheme = "instagram-stories"
    c.host = "share"
    c.queryItems = [URLQueryItem(name: "source_application", value: appId)]
    return c.url
  }

  static func stickerImageData(fromPng pngData: Data) -> Data? {
    if let uiImage = UIImage(data: pngData), let jpeg = uiImage.jpegData(compressionQuality: 0.95) {
      return jpeg
    }
    return pngData.isEmpty ? nil : pngData
  }
}

class SceneDelegate: FlutterSceneDelegate {
  /// UIScene 사용 시 OAuth 콜백은 여기로 옵니다. 전달하지 않으면 `GoogleSignIn.signIn()` 이 영원히 완료되지 않습니다.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      _ = GIDSignIn.sharedInstance.handle(context.url)
    }
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    registerFlutterNativeChannelsIfNeeded(scene: scene)
  }

  private func registerFlutterNativeChannelsIfNeeded(scene: UIScene) {
    guard !FlutterNativeChannelsSetup.done else { return }
    guard let windowScene = scene as? UIWindowScene else { return }
    guard let root = windowScene.windows.first?.rootViewController as? FlutterViewController else {
      return
    }
    FlutterNativeChannelsSetup.done = true
    let messenger = root.engine.binaryMessenger

    let settingsChannel = FlutterMethodChannel(
      name: "com.o2a.ketchup/settings",
      binaryMessenger: messenger
    )
    settingsChannel.setMethodCallHandler { call, result in
      if call.method == "isICloudAvailable" {
        CKContainer.default().accountStatus { status, _ in
          DispatchQueue.main.async {
            result(status == .available)
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let instagramChannel = FlutterMethodChannel(
      name: "com.o2a.ketchup/instagram_story",
      binaryMessenger: messenger
    )
    instagramChannel.setMethodCallHandler { call, result in
      if call.method == "shareInstagramStorySticker" {
        guard
          let args = call.arguments as? [String: Any],
          let typed = args["png"] as? FlutterStandardTypedData
        else {
          result(FlutterError(code: "bad_args", message: "png required", details: nil))
          return
        }
        let pngData = typed.data
        guard let appId = InstagramStoryShare.facebookAppIdFromPlist() else {
          result(
            FlutterError(
              code: "missing_facebook_app_id",
              message:
                "Info.plist의 FacebookAppID가 비어 있습니다. Meta 개발자 콘솔(https://developers.facebook.com)에서 앱을 만든 뒤 숫자 앱 ID를 넣고, 설정 > 기본 설정에서 이 앱의 iOS 번들 ID를 등록해야 스토리 공유가 됩니다.",
              details: nil
            ))
          return
        }
        guard let storiesUrl = InstagramStoryShare.storiesShareURL(appId: appId) else {
          result(false)
          return
        }
        guard let stickerData = InstagramStoryShare.stickerImageData(fromPng: pngData) else {
          result(false)
          return
        }
        guard UIApplication.shared.canOpenURL(storiesUrl) else {
          result(false)
          return
        }
        // Meta 공식 iOS 샘플: sticker + 배경색만 (URL에만 source_application).
        let pasteboardItems: [String: Any] = [
          "com.instagram.sharedSticker.stickerImage": stickerData,
          "com.instagram.sharedSticker.backgroundTopColor": "#F2ECDF",
          "com.instagram.sharedSticker.backgroundBottomColor": "#F2ECDF",
        ]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
          .expirationDate: Date().addingTimeInterval(300),
        ]
        DispatchQueue.main.async {
          UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
          UIApplication.shared.open(storiesUrl, options: [:]) { ok in
            DispatchQueue.main.async {
              result(ok)
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let legacyRestoreChannel = FlutterMethodChannel(
      name: "com.o2a.ketchup/legacy_restore",
      binaryMessenger: messenger
    )
    legacyRestoreChannel.setMethodCallHandler { call, result in
      if call.method == "parseLegacyRealmEntries" {
        guard
          let args = call.arguments as? [String: Any],
          let typed = args["realm"] as? FlutterStandardTypedData
        else {
          result(FlutterError(code: "bad_args", message: "realm bytes required", details: nil))
          return
        }
        self.parseLegacyRealmEntries(realmBytes: typed.data, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func parseLegacyRealmEntries(realmBytes: Data, result: @escaping FlutterResult) {
    let fm = FileManager.default
    let tmpDir = fm.temporaryDirectory
    let realmURL = tmpDir.appendingPathComponent("legacy_restore_\(Date().timeIntervalSince1970).realm")
    let lockURL = realmURL.appendingPathExtension("lock")
    let noteURL = realmURL.appendingPathExtension("note")
    let managementURL = realmURL.appendingPathExtension("management")
    do {
      try realmBytes.write(to: realmURL, options: .atomic)
      defer {
        try? fm.removeItem(at: realmURL)
        try? fm.removeItem(at: lockURL)
        try? fm.removeItem(at: noteURL)
        try? fm.removeItem(at: managementURL)
      }

      // 일부 구버전 Realm 파일은 포맷 업그레이드가 필요해 readOnly로는 열 수 없습니다.
      // 임시 경로에서 쓰기 가능한 설정으로 열어 마이그레이션 후 읽습니다.
      // 네이티브 Ketchup 앱은 `DataRealm` 클래스로 저장합니다. 이름이 다르면 테이블이 비어 보입니다.
      var config = Realm.Configuration(fileURL: realmURL, readOnly: false, objectTypes: [DataRealmBridge.self])
      config.schemaVersion = 0
      let realm = try Realm(configuration: config)
      let objects = realm.objects(DataRealmBridge.self).sorted(byKeyPath: "id", ascending: true)
      var rows: [[String: Any]] = []
      rows.reserveCapacity(objects.count)
      for obj in objects {
        var row: [String: Any] = [
          "id": obj.id,
          "defaultImage": obj.defaultImage,
          "text": obj.text,
        ]
        if let date = obj.date {
          row["dateMs"] = Int(date.timeIntervalSince1970 * 1000.0)
        }
        if let imageData = obj.imageData, !imageData.isEmpty {
          row["imageBase64"] = imageData.base64EncodedString()
        }
        rows.append(row)
      }
      result(rows)
    } catch {
      result(FlutterError(code: "legacy_realm_parse_failed", message: error.localizedDescription, details: nil))
    }
  }
}

/// 구 iOS 앱 `Ketchup/DataRealm.swift` 와 동일한 Realm 클래스명(`DataRealm`)으로 읽어야 합니다.
@objc(DataRealm)
final class DataRealmBridge: Object {
  @Persisted(primaryKey: true) var id: Int = 0
  @Persisted var defaultImage: Int = 0
  @Persisted var date: Date?
  @Persisted var text: String = ""
  @Persisted var page: Int = 0
  @Persisted var imageData: Data?
}
