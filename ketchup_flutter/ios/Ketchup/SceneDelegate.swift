import CloudKit
import Flutter
import GoogleSignIn
import RealmSwift
import UIKit

private enum FlutterNativeChannelsSetup {
  static var done = false
  static var pluginsRegistered = false
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
  /// 기본 존(`_defaultZone`)은 CloudKit에서 `getChanges`/무제한 CKQuery가 막히는 경우가 많아
  /// Flutter 일기는 전용 존에만 저장합니다.
  private static let flutterDiaryZoneName = "KetchupFlutterDiary"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    registerFlutterNativeChannelsWhenReady(scene: scene, retries: 12)
  }

  /// UIScene 사용 시 OAuth 콜백은 여기로 옵니다. 전달하지 않으면 `GoogleSignIn.signIn()` 이 영원히 완료되지 않습니다.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      _ = GIDSignIn.sharedInstance.handle(context.url)
    }
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    registerFlutterNativeChannelsWhenReady(scene: scene, retries: 6)
  }

  private func registerFlutterNativeChannelsWhenReady(scene: UIScene, retries: Int) {
    if registerFlutterNativeChannelsIfNeeded(scene: scene) {
      return
    }
    guard retries > 0 else {
      print("[icloud] channel registration failed: FlutterViewController not ready")
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.registerFlutterNativeChannelsWhenReady(scene: scene, retries: retries - 1)
    }
  }

  @discardableResult
  private func registerFlutterNativeChannelsIfNeeded(scene: UIScene) -> Bool {
    guard !FlutterNativeChannelsSetup.done else { return true }
    guard let windowScene = scene as? UIWindowScene else { return false }
    guard let root = windowScene.windows.first?.rootViewController as? FlutterViewController else {
      return false
    }
    if !FlutterNativeChannelsSetup.pluginsRegistered {
      // Register plugins on the same engine bound to the visible FlutterViewController.
      GeneratedPluginRegistrant.register(with: root.engine)
      FlutterNativeChannelsSetup.pluginsRegistered = true
    }
    FlutterNativeChannelsSetup.done = true
    let messenger = root.engine.binaryMessenger

    let settingsChannel = FlutterMethodChannel(
      name: "com.o2a.ketchup/settings",
      binaryMessenger: messenger
    )
    settingsChannel.setMethodCallHandler { call, result in
      if call.method == "isICloudAvailable" {
        // 저장·조회와 동일 컨테이너 (Entitlements 의 iCloud.com.ketchup).
        CKContainer(identifier: "iCloud.com.ketchup").accountStatus { status, _ in
          DispatchQueue.main.async {
            result(status == .available)
          }
        }
      } else if call.method == "fetchICloudDays" {
        self.fetchICloudDays(result: result)
      } else if call.method == "debugICloudStatus" {
        self.debugICloudStatus(result: result)
      } else if call.method == "clearICloudDays" {
        self.clearICloudDays(result: result)
      } else if call.method == "upsertICloudDay" {
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "map required", details: nil))
          return
        }
        self.upsertFlutterDiaryDay(args: args, result: result)
      } else if call.method == "deleteICloudDay" {
        guard let syncKey = call.arguments as? String, !syncKey.isEmpty else {
          result(FlutterError(code: "bad_args", message: "syncKey required", details: nil))
          return
        }
        self.deleteFlutterDiaryDay(syncKey: syncKey, result: result)
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
    return true
  }

  private func flutterDiaryZoneID() -> CKRecordZone.ID {
    CKRecordZone(zoneName: Self.flutterDiaryZoneName).zoneID
  }

  /// Flutter 전용 존 생성(멱등). 기본 존에 쓰면 zoneChanges/쿼리가 실패하는 환경이 많습니다.
  private func ensureFlutterDiaryZone(db: CKDatabase, completion: @escaping () -> Void) {
    let zone = CKRecordZone(zoneName: Self.flutterDiaryZoneName)
    let op = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
    op.modifyRecordZonesCompletionBlock = { _, _, error in
      if let error = error {
        print("[icloud] ensureFlutterDiaryZone: \(error)")
      }
      completion()
    }
    db.add(op)
  }

  /// CKQuery 없이 zone changes만 사용 (대시보드에 queryable 인덱스 불필요).
  private func fetchFlutterDiaryRowsViaZoneChanges(
    db: CKDatabase,
    completion: @escaping ([[String: Any]]) -> Void
  ) {
    let zoneID = flutterDiaryZoneID()
    let cfg = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
    cfg.previousServerChangeToken = nil
    let op = CKFetchRecordZoneChangesOperation(
      recordZoneIDs: [zoneID],
      configurationsByRecordZoneID: [zoneID: cfg]
    )
    var rowsById: [Int: [String: Any]] = [:]
    op.recordChangedBlock = { record in
      guard record.recordType == "FlutterDiaryDay" else { return }
      if let row = self.mapCloudDay(record: record), let id = self.diaryRowIdFromMap(row) {
        rowsById[id] = row
      }
    }
    op.fetchRecordZoneChangesCompletionBlock = { error in
      if let error = error {
        print("[icloud] Flutter zone changes error: \(error)")
        completion([])
        return
      }
      completion(Array(rowsById.values))
    }
    db.add(op)
  }

  private func fetchICloudDays(result: @escaping FlutterResult) {
    let container = CKContainer(identifier: "iCloud.com.ketchup")
    container.accountStatus { status, _ in
      print("[icloud] accountStatus=\(status.rawValue)")
      guard status == .available else {
        DispatchQueue.main.async { result([]) }
        return
      }
      let db = container.privateCloudDatabase
      self.ensureFlutterDiaryZone(db: db) {
        self.fetchFlutterDiaryRowsViaZoneChanges(db: db) { flutterRows in
          print("[icloud] FlutterDiary zone rows=\(flutterRows.count)")
          // 성능: 최신(Flutter 전용 존) 데이터가 이미 있으면 legacy private zone 전체 스캔을 생략합니다.
          // (legacy 스캔은 flutterRows가 비었을 때만 수행)
          if !flutterRows.isEmpty {
            DispatchQueue.main.async { result(flutterRows) }
            return
          }
          self.fetchAllZoneIDs(db: db) { zoneIDs in
            let defaultZ = CKRecordZone.default().zoneID
            let flutterZ = self.flutterDiaryZoneID()
            let legacyZones = zoneIDs.filter { z in
              z.zoneName != defaultZ.zoneName && z.zoneName != flutterZ.zoneName
            }
            self.fetchAllRecordsFromZones(db: db, zoneIDs: legacyZones) { legacyRows in
              print("[icloud] legacy zone-scan rows=\(legacyRows.count)")
              var merged: [Int: [String: Any]] = [:]
              for r in flutterRows {
                if let id = self.diaryRowIdFromMap(r) {
                  merged[id] = r
                }
              }
              for r in legacyRows {
                if let id = self.diaryRowIdFromMap(r) {
                  merged[id] = r
                }
              }
              DispatchQueue.main.async { result(Array(merged.values)) }
            }
          }
        }
      }
    }
  }

  private func debugICloudStatus(result: @escaping FlutterResult) {
    let container = CKContainer(identifier: "iCloud.com.ketchup")
    container.accountStatus { status, _ in
      guard status == .available else {
        DispatchQueue.main.async {
          result([
            "available": false,
            "zoneCount": 0,
            "changedRecords": 0,
            "mappableRows": 0,
            "nonMappableRecords": 0,
          ])
        }
        return
      }
      let db = container.privateCloudDatabase
      self.fetchAllZoneIDs(db: db) { zoneIDs in
        self.collectICloudDiagnostics(db: db, zoneIDs: zoneIDs) { changed, mappable, nonMappable in
          DispatchQueue.main.async {
            result([
              "available": true,
              "zoneCount": zoneIDs.count,
              "changedRecords": changed,
              "mappableRows": mappable,
              "nonMappableRecords": nonMappable,
            ])
          }
        }
      }
    }
  }

  /// Flutter 앱이 저장하는 일기 레코드 (private DB, 전용 존 [flutterDiaryZoneName]).
  private func upsertFlutterDiaryDay(args: [String: Any], result: @escaping FlutterResult) {
    guard let syncKey = args["syncKey"] as? String, !syncKey.isEmpty,
      let id = args["id"] as? Int,
      let text = args["text"] as? String,
      let defaultImage = args["defaultImage"] as? Int
    else {
      result(FlutterError(code: "bad_args", message: "syncKey,id,text,defaultImage required", details: nil))
      return
    }
    let dateMs: Int64 = {
      if let n = args["dateMs"] as? NSNumber {
        return n.int64Value
      }
      if let i = args["dateMs"] as? Int {
        return Int64(i)
      }
      if let i = args["dateMs"] as? Int64 {
        return i
      }
      return 0
    }()
    guard dateMs != 0 else {
      result(FlutterError(code: "bad_args", message: "dateMs required", details: nil))
      return
    }
    let imageBase64 = args["imageBase64"] as? String

    let container = CKContainer(identifier: "iCloud.com.ketchup")
    container.accountStatus { status, accountError in
      if accountError != nil {
        print("[icloud] upsert accountStatus err \(String(describing: accountError))")
      }
      guard status == .available else {
        DispatchQueue.main.async { result(false) }
        return
      }
      let db = container.privateCloudDatabase
      let zoneID = self.flutterDiaryZoneID()
      self.ensureFlutterDiaryZone(db: db) {
        let recordID = CKRecord.ID(recordName: syncKey, zoneID: zoneID)
        let record = CKRecord(recordType: "FlutterDiaryDay", recordID: recordID)
        let idNum = NSNumber(value: id)
        record["id"] = idNum
        record["CD_id"] = idNum
        record["text"] = text as NSString
        record["CD_text"] = text as NSString
        let date = Date(timeIntervalSince1970: TimeInterval(dateMs) / 1000.0)
        record["date"] = date as CKRecordValue
        record["CD_date"] = date as CKRecordValue
        let defNum = NSNumber(value: defaultImage)
        record["defaultImage"] = defNum
        record["CD_defaultImage"] = defNum

        var tmpURL: URL?
        if let b64 = imageBase64, !b64.isEmpty, let data = Data(base64Encoded: b64), !data.isEmpty {
          let u = FileManager.default.temporaryDirectory.appendingPathComponent("ketchup_ck_\(UUID().uuidString).jpg")
          do {
            try data.write(to: u, options: .atomic)
            tmpURL = u
            let asset = CKAsset(fileURL: u)
            record["imageData"] = asset
            record["CD_imageData"] = asset
          } catch {
            print("[icloud] image temp write failed \(error)")
          }
        }

        let op = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        op.savePolicy = .allKeys
        op.modifyRecordsCompletionBlock = { _, _, error in
          if let u = tmpURL {
            try? FileManager.default.removeItem(at: u)
          }
          if let error = error {
            print("[icloud] upsert modify error \(error)")
            DispatchQueue.main.async {
              result(FlutterError(code: "ck_modify", message: error.localizedDescription, details: nil))
            }
          } else {
            print("[icloud] upsert OK syncKey=\(syncKey) zone=\(Self.flutterDiaryZoneName)")
            DispatchQueue.main.async { result(true) }
          }
        }
        db.add(op)
      }
    }
  }

  private func deleteFlutterDiaryDay(syncKey: String, result: @escaping FlutterResult) {
    let container = CKContainer(identifier: "iCloud.com.ketchup")
    container.accountStatus { status, _ in
      guard status == .available else {
        DispatchQueue.main.async { result(false) }
        return
      }
      let db = container.privateCloudDatabase
      let recordID = CKRecord.ID(recordName: syncKey, zoneID: self.flutterDiaryZoneID())
      let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
      op.modifyRecordsCompletionBlock = { _, deletedIDs, error in
        if let error = error {
          let nsErr = error as NSError
          if nsErr.domain == CKErrorDomain, nsErr.code == CKError.unknownItem.rawValue {
            DispatchQueue.main.async { result(true) }
            return
          }
          print("[icloud] delete error \(error)")
          DispatchQueue.main.async {
            result(FlutterError(code: "ck_delete", message: error.localizedDescription, details: nil))
          }
        } else {
          DispatchQueue.main.async { result(true) }
        }
      }
      db.add(op)
    }
  }

  private func clearICloudDays(result: @escaping FlutterResult) {
    let container = CKContainer(identifier: "iCloud.com.ketchup")
    container.accountStatus { status, _ in
      guard status == .available else {
        DispatchQueue.main.async { result(0) }
        return
      }
      let db = container.privateCloudDatabase
      self.fetchAllZoneIDs(db: db) { zoneIDs in
        self.collectDiaryRecordIDs(db: db, zoneIDs: zoneIDs) { recordIDs in
          guard !recordIDs.isEmpty else {
            DispatchQueue.main.async { result(0) }
            return
          }
          self.deleteRecordIDs(db: db, recordIDs: recordIDs) { deleted in
            DispatchQueue.main.async { result(deleted) }
          }
        }
      }
    }
  }

  private func fetchAllZoneIDs(db: CKDatabase, completion: @escaping ([CKRecordZone.ID]) -> Void) {
    let op = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
    op.fetchRecordZonesCompletionBlock = { zonesById, _ in
      // zone 지정 없이 조회(nil)는 기본 존만 대상으로 동작할 수 있어,
      // Core Data CloudKit 커스텀 존까지 포함하려면 모든 private 존을 순회해야 합니다.
      let all = zonesById?.keys.map { $0 } ?? []
      print("[icloud] zones=\(all.count)")
      completion(all)
    }
    db.add(op)
  }

  /// 여러 존을 **병렬**로 `CKFetchRecordZoneChangesOperation` 하면 완료 핸들러가
  /// 임의 큐에서 동시에 `remaining` 을 감소시켜 레이스가 나고, `completion` 이
  /// 호출되지 않는 경우가 있어 Flutter 측 `fetchICloudDays` 가 무한 대기합니다.
  /// 존은 순차 처리합니다.
  private func fetchAllRecordsFromZones(
    db: CKDatabase,
    zoneIDs: [CKRecordZone.ID],
    completion: @escaping ([[String: Any]]) -> Void
  ) {
    let defaultZ = CKRecordZone.default().zoneID
    let targets = zoneIDs.filter { $0.zoneName != defaultZ.zoneName }
    var rowsById: [Int: [String: Any]] = [:]

    func fetchAtIndex(_ index: Int) {
      if index >= targets.count {
        completion(Array(rowsById.values))
        return
      }
      let zoneID = targets[index]
      let cfg = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
      cfg.previousServerChangeToken = nil

      let op = CKFetchRecordZoneChangesOperation(
        recordZoneIDs: [zoneID],
        configurationsByRecordZoneID: [zoneID: cfg]
      )

      op.recordChangedBlock = { record in
        if let row = self.mapCloudDay(record: record), let id = self.diaryRowIdFromMap(row) {
          rowsById[id] = row
        }
      }
      op.recordWithIDWasDeletedBlock = { _, _ in }
      op.recordZoneFetchCompletionBlock = { _, _, _, _, _ in }
      op.fetchRecordZoneChangesCompletionBlock = { error in
        if let error = error {
          print("[icloud] zoneChanges error zone=\(zoneID): \(error)")
        }
        fetchAtIndex(index + 1)
      }
      db.add(op)
    }

    if targets.isEmpty {
      completion([])
      return
    }
    fetchAtIndex(0)
  }

  private func collectICloudDiagnostics(
    db: CKDatabase,
    zoneIDs: [CKRecordZone.ID],
    completion: @escaping (Int, Int, Int) -> Void
  ) {
    let defaultZ = CKRecordZone.default().zoneID
    let flutterZ = flutterDiaryZoneID()
    var merged = zoneIDs
    if !merged.contains(where: { $0.zoneName == flutterZ.zoneName }) {
      merged.append(flutterZ)
    }
    let targets = merged.filter { $0.zoneName != defaultZ.zoneName }
    var changedRecords = 0
    var mappableRows = 0
    var nonMappable = 0

    func fetchAtIndex(_ index: Int) {
      if index >= targets.count {
        completion(changedRecords, mappableRows, nonMappable)
        return
      }
      let zoneID = targets[index]
      let cfg = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
      cfg.previousServerChangeToken = nil
      let op = CKFetchRecordZoneChangesOperation(
        recordZoneIDs: [zoneID],
        configurationsByRecordZoneID: [zoneID: cfg]
      )
      op.recordChangedBlock = { record in
        changedRecords += 1
        if self.mapCloudDay(record: record) != nil {
          mappableRows += 1
        } else {
          nonMappable += 1
          print("[icloud][diag] non-mappable recordType=\(record.recordType) keys=\(record.allKeys())")
        }
      }
      op.fetchRecordZoneChangesCompletionBlock = { _ in
        fetchAtIndex(index + 1)
      }
      db.add(op)
    }

    if targets.isEmpty {
      completion(0, 0, 0)
      return
    }
    fetchAtIndex(0)
  }

  private func collectDiaryRecordIDs(
    db: CKDatabase,
    zoneIDs: [CKRecordZone.ID],
    completion: @escaping ([CKRecord.ID]) -> Void
  ) {
    let defaultZ = CKRecordZone.default().zoneID
    let flutterZ = flutterDiaryZoneID()
    var merged = zoneIDs
    if !merged.contains(where: { $0.zoneName == flutterZ.zoneName }) {
      merged.append(flutterZ)
    }
    let targets = merged.filter { $0.zoneName != defaultZ.zoneName }
    var ids: [CKRecord.ID] = []

    func fetchAtIndex(_ index: Int) {
      if index >= targets.count {
        completion(ids)
        return
      }
      let zoneID = targets[index]
      let cfg = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
      cfg.previousServerChangeToken = nil
      let op = CKFetchRecordZoneChangesOperation(
        recordZoneIDs: [zoneID],
        configurationsByRecordZoneID: [zoneID: cfg]
      )
      op.recordChangedBlock = { record in
        if self.mapCloudDay(record: record) != nil {
          ids.append(record.recordID)
        }
      }
      op.fetchRecordZoneChangesCompletionBlock = { _ in
        fetchAtIndex(index + 1)
      }
      db.add(op)
    }

    if targets.isEmpty {
      completion([])
      return
    }
    fetchAtIndex(0)
  }

  private func deleteRecordIDs(
    db: CKDatabase,
    recordIDs: [CKRecord.ID],
    completion: @escaping (Int) -> Void
  ) {
    if recordIDs.isEmpty {
      completion(0)
      return
    }
    let chunkSize = 350
    let chunks: [[CKRecord.ID]] = stride(from: 0, to: recordIDs.count, by: chunkSize).map {
      Array(recordIDs[$0..<min($0 + chunkSize, recordIDs.count)])
    }
    var deleted = 0

    func deleteChunkIndex(_ index: Int) {
      if index >= chunks.count {
        completion(deleted)
        return
      }
      let chunk = chunks[index]
      let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: chunk)
      op.savePolicy = .ifServerRecordUnchanged
      op.modifyRecordsCompletionBlock = { _, deletedIDs, _ in
        deleted += deletedIDs?.count ?? 0
        deleteChunkIndex(index + 1)
      }
      db.add(op)
    }

    deleteChunkIndex(0)
  }

  /// Flutter / CloudKit 브리지에서 [String:Any] 의 id 가 Int 또는 NSNumber 일 수 있습니다.
  private func diaryRowIdFromMap(_ row: [String: Any]) -> Int? {
    if let v = row["id"] as? Int {
      return v
    }
    if let n = row["id"] as? NSNumber {
      return n.intValue
    }
    return nil
  }

  private func mapCloudDay(record: CKRecord) -> [String: Any]? {
    // NSPersistentCloudKitContainer 기반 레코드는 필드명이 CD_* 로 저장될 수 있어 양쪽 키를 모두 시도.
    let idValue: Int? = {
      if let n = record["id"] as? NSNumber { return n.intValue }
      if let n = record["CD_id"] as? NSNumber { return n.intValue }
      if let v = record["id"] as? Int64 { return Int(v) }
      if let v = record["CD_id"] as? Int64 { return Int(v) }
      if let v = record["id"] as? Int { return v }
      if let v = record["CD_id"] as? Int { return v }
      return nil
    }()
    let textValue = (record["text"] as? String) ?? (record["CD_text"] as? String) ?? ""
    let defaultImageValue = (record["defaultImage"] as? NSNumber)?.intValue
      ?? (record["CD_defaultImage"] as? NSNumber)?.intValue ?? 0
    let dateValue = (record["date"] as? Date) ?? (record["CD_date"] as? Date)
    guard let id = idValue, let date = dateValue else {
      return nil
    }
    var row: [String: Any] = [
      "id": id,
      "text": textValue,
      "defaultImage": defaultImageValue,
      "dateMs": Int(date.timeIntervalSince1970 * 1000.0)
    ]
    if let imageData = extractImageData(record: record) {
      row["imageBase64"] = imageData.base64EncodedString()
    }
    return row
  }

  private func extractImageData(record: CKRecord) -> Data? {
    // Core Data + CloudKit 미러링에서는 바이너리 필드가 다양한 이름/포맷으로 저장될 수 있습니다.
    // 예: imageData, CD_imageData, *_ckAsset, Transformable 아카이브(Data/UIImage/Dictionary).
    var candidateKeys: [String] = ["imageData", "CD_imageData", "imageData_ckAsset", "CD_imageData_ckAsset"]
    for key in record.allKeys() where key.localizedCaseInsensitiveContains("imagedata")
      || key.localizedCaseInsensitiveContains("image")
    {
      if !candidateKeys.contains(key) {
        candidateKeys.append(key)
      }
    }

    for key in candidateKeys {
      guard let value = record[key] else { continue }
      if let data = value as? Data,
        let normalized = normalizedImageData(from: data)
      {
        return normalized
      }
      if let asset = value as? CKAsset,
        let url = asset.fileURL,
        let raw = try? Data(contentsOf: url),
        let normalized = normalizedImageData(from: raw)
      {
        return normalized
      }
    }
    return nil
  }

  private func normalizedImageData(from raw: Data) -> Data? {
    guard !raw.isEmpty else { return nil }
    if let img = UIImage(data: raw) {
      return img.jpegData(compressionQuality: 0.95) ?? raw
    }

    // Transformable/아카이브 포맷 복원 시도
    if let obj = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(raw) {
      if let data = obj as? Data, let img = UIImage(data: data) {
        return img.jpegData(compressionQuality: 0.95) ?? data
      }
      if let img = obj as? UIImage {
        return img.jpegData(compressionQuality: 0.95)
      }
      if let dict = obj as? [String: Any] {
        if let data = dict["NS.data"] as? Data, let img = UIImage(data: data) {
          return img.jpegData(compressionQuality: 0.95) ?? data
        }
      }
    }
    return nil
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
