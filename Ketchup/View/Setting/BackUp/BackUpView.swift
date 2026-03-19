//
//
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift
import RxCocoa
import Kingfisher
import GoogleSignIn
import Firebase
import GoogleAPIClientForREST
import GTMSessionFetcher
import CoreData
import Lottie
import FirebaseAuth

class BackUpView: XibView{
    
    @IBOutlet weak var close_btn: UIButton!
    @IBOutlet weak var backup_date_label: UILabel!
    @IBOutlet weak var login_btn: UIButton!
    @IBOutlet weak var backup_btn: UIButton!
    @IBOutlet weak var restore_btn: UIButton!
    @IBOutlet weak var iclude_btn: UIButton!
    @IBOutlet weak var google_id_label: UILabel!
    
    @IBOutlet weak var loading_view: UIView!
    @IBOutlet weak var lottie_view: UIView!
    
    let googleDriveService = GTLRDriveService()
    var googleUser: GIDGoogleUser?
    var uploadFolderID: String?
    var lottieAnimation = LottieAnimationView()
    
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    lazy var persistenContainer = CoreDataManager.persistenContainer
    
    weak var mainView : ViewController!
    
    var isGoogleLogin = false
    
    let bag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            isInitailized = false
            initialize()
        }
    }

    func initialize(){
        setView()
        bind()
    }
    
    func setView(){
        self.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)
        
        if self.appDelegate.cloudStatus {
            iclude_btn.setTitle("on", for: .normal)
        }
        else {
            iclude_btn.setTitle("off", for: .normal)
        }

        setLottieImage()
        autoGoogleLogin()
    }
    
    func bind(){
        close_btn.rx.tap
            .bind { (_) in
                self.removeFromSuperview()
        }.disposed(by: bag)
        
        login_btn.rx.tap
            .bind { (_) in
                self.googleLogin()
        }.disposed(by: bag)
        
        backup_btn.rx.tap
            .bind { (_) in
                if self.isGoogleLogin == false{
                    Toast.show("구글 로그인 먼저 해주세요.")
                }
                else {
                    self.loadingStart()
                    self.populateFolderID()
                }
        }.disposed(by: bag)
        
        restore_btn.rx.tap
            .bind { (_) in
                if self.isGoogleLogin == false{
                    Toast.show("구글 로그인 먼저 해주세요.")
                }
                else {
                    Alert.message("백업하지 않은 기존 데이터는 삭제돼요. 복원할까요?", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                        self.loadingStart()
                        self.getAndSaveFileromGoogle()
                    }))
                }
        }.disposed(by: bag)
        
        
        iclude_btn.rx.tap
            .bind { (_) in
                self.appDelegate.isICloudContainerAvailable()
                if self.appDelegate.cloudStatus {
                    if !UserDefaults.standard.bool(forKey: "useICloud") {
                        self.loadingStart()
                        UserDefaults.standard.set(true, forKey: "useICloud")
                        self.iclude_btn.setTitle("on", for: .normal)
                        self.setData(completion: {
                        })
                    }
                    else {
                        self.iclude_btn.setTitle("off", for: .normal)
                        UserDefaults.standard.set(false, forKey: "useICloud")
                    }
                }
                else {
                    Alert.message("ICloud를 상태를 확인해주세요.", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                        return
                    }))
                }
        }.disposed(by: bag)
    }
    
    
    /* ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ Google ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ */
    
    private enum BackupFileName {
        static let driveFolder = "Ketchup"
        
        static let realm = "default.realm"
        
        static let coreDataSQLite = "DayModel.sqlite"
        static let coreDataSQLiteWAL = "DayModel.sqlite-wal"
        static let coreDataSQLiteSHM = "DayModel.sqlite-shm"
        
        static let all: [String] = [realm, coreDataSQLite, coreDataSQLiteWAL, coreDataSQLiteSHM]
    }
    
    private func documentsURL(_ name: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(name)
    }
    
    private func appSupportURL(_ name: String) -> URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(name)
    }
    
    private func ensureAppSupportDirectoryExists() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    
    private func isSignedInWithDriveScope() -> Bool {
        guard let googleUser = googleUser else { return false }
        return googleUser.grantedScopes?.contains("https://www.googleapis.com/auth/drive") == true
    }
    
    private func ensureGoogleDriveAuthorized(_ completion: @escaping (Bool) -> Void) {
        guard let googleUser = googleUser else {
            completion(false)
            return
        }
        
        // If previous sign-in didn't include Drive scope, request it.
        if isSignedInWithDriveScope() {
            completion(true)
            return
        }
        
        // GoogleSignIn SDK versions differ on "addScopes" API availability.
        // Re-run sign-in with the required scope so consent can be granted.
        let additionalScopes = ["https://www.googleapis.com/auth/drive"]
        GIDSignIn.sharedInstance.signIn(withPresenting: getNavigationController(), hint: nil, additionalScopes: additionalScopes) { signResult, error in
            if let error = error {
                log.d(error.localizedDescription)
                completion(false)
                return
            }
            guard let user = signResult?.user else {
                completion(false)
                return
            }
            self.googleDriveService.authorizer = user.fetcherAuthorizer
            self.googleUser = user
            completion(true)
        }
    }
    
    func autoGoogleLogin(){
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        if GoogleSignIn.GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GoogleSignIn.GIDSignIn.sharedInstance.restorePreviousSignIn() { signResult, error in
                if let error = error {
                    log.d(error.localizedDescription)
                    self.isGoogleLogin = false
                    return
                }
                guard let result = signResult else {
                    self.isGoogleLogin = false
                    return
                }
                self.google_id_label.text = "ID \(result.profile?.email ?? "No email")"
                self.googleDriveService.authorizer = result.fetcherAuthorizer
                self.googleUser = result
                self.isGoogleLogin = true
            }
        }else {
            log.d("구글 로그인 한적이 없어서 한번은 해야함.")
        }
    }
    
    
    func googleLogin(){
        let additionalScopes = ["https://www.googleapis.com/auth/drive"]
        GIDSignIn.sharedInstance.signIn(withPresenting: getNavigationController(), hint: nil, additionalScopes: additionalScopes) { signResult, error in
            if let error = error {
                log.d(error.localizedDescription)
                self.isGoogleLogin = false
                return
            }
            guard let result = signResult else {
                self.isGoogleLogin = false
                return
            }
            
            self.google_id_label.text = "ID \(result.user.profile?.email ?? "No email")"
            
            self.googleDriveService.authorizer = result.user.fetcherAuthorizer
            self.googleUser = result.user
            self.isGoogleLogin = true
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        guard let googleUser = user else {
            return
        }
        
        log.d("User email: \(googleUser.profile?.email ?? "No email")")
        if error == nil {
            self.googleDriveService.authorizer = googleUser.fetcherAuthorizer
            self.googleUser = googleUser
        } else {
            self.googleDriveService.authorizer = nil
            self.googleUser = nil
        }
        
        google_id_label.text = "ID \(googleUser.profile?.email ?? "No email")"
    }
    
    
    //1. 백업시작
    func populateFolderID() {
        let myFolderName = BackupFileName.driveFolder
        
        guard let googleUser = googleUser else {
            return
        }
        
        ensureGoogleDriveAuthorized { ok in
            if !ok {
                Toast.show("구글 Drive 권한이 필요해요.")
                self.fileRecovery()
                return
            }
            
            self.getFolderID(name: myFolderName, service: self.googleDriveService, user: googleUser) {
            self.uploadFolderID = $0
            if self.uploadFolderID == nil {
                    self.createFolder (name : myFolderName, service : self.googleDriveService) {
                        self.uploadFolderID = $0
                        self.backup()
                    }
            } else {
                    // 폴더가 이미 있습니다.
                    self.backup()
            }
            }
        }

    }
    
    
    //2. 기본폴더 검색
    func getFolderID(name: String, service: GTLRDriveService, user: GIDGoogleUser, completion: @escaping (String?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.spaces = "drive"
        
        query.corpora = "user"
            
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        let ownedByUser = "'me' in owners"
        query.q = "\(withName) and \(foldersOnly) and \(ownedByUser) and trashed=false"
        
        log.d(user)
        service.executeQuery(query) { (_, result, error) in
            log.d(result)
            guard let result = result else {
                completion(nil)
                return
            }
            if let unwrappedError = error {
                Toast.show("업로드를 실패ㅜ")
                log.d(unwrappedError.localizedDescription)
            }
                                     
            let folderList = result as! GTLRDrive_FileList
            completion(folderList.files?.first?.identifier)
        }
    }
    
    
    
    //3. 폴더 없으면 생성
    func createFolder(name: String, service: GTLRDriveService, completion: @escaping (String) -> Void) {
        let folder = GTLRDrive_File()
        folder.mimeType = "application/vnd.google-apps.folder"
        folder.name = name
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        
        self.googleDriveService.executeQuery(query) { (_, file, error) in
            log.d(self.googleUser?.profile?.email)
            guard let file = file else {
                completion("")
                return
            }
            if let unwrappedError = error {
                Toast.show("업로드를 실패ㅜ.")
                log.d(unwrappedError.localizedDescription)
            }
            
            let folder = file as! GTLRDrive_File
            completion(folder.identifier!)
        }
    }

    
    func backup(){
        guard let folderID = uploadFolderID, !folderID.isEmpty else {
            fileRecovery()
            return
        }
        
        ensureAppSupportDirectoryExists()
        
        let realmURL = documentsURL(BackupFileName.realm)
        let sqliteURL = appSupportURL(BackupFileName.coreDataSQLite)
        let walURL = appSupportURL(BackupFileName.coreDataSQLiteWAL)
        let shmURL = appSupportURL(BackupFileName.coreDataSQLiteSHM)
        
        // Realm (always)
        uploadOrUpdateFile(name: BackupFileName.realm, folderID: folderID, fileURL: realmURL, mimeType: "application/x-realm", service: googleDriveService)
        
        // CoreData (upload all sqlite pieces if present)
        if FileManager.default.fileExists(atPath: sqliteURL.path) {
            uploadOrUpdateFile(name: BackupFileName.coreDataSQLite, folderID: folderID, fileURL: sqliteURL, mimeType: "application/x-sqlite3", service: googleDriveService)
        }
        if FileManager.default.fileExists(atPath: walURL.path) {
            uploadOrUpdateFile(name: BackupFileName.coreDataSQLiteWAL, folderID: folderID, fileURL: walURL, mimeType: "application/octet-stream", service: googleDriveService)
        }
        if FileManager.default.fileExists(atPath: shmURL.path) {
            uploadOrUpdateFile(name: BackupFileName.coreDataSQLiteSHM, folderID: folderID, fileURL: shmURL, mimeType: "application/octet-stream", service: googleDriveService)
        }
    }

    /*
     파일업로드
     */
    func uploadOrUpdateFile(name: String, folderID: String, fileURL: URL, mimeType: String, service: GTLRDriveService) {
        // Find existing file in folder to update instead of creating duplicates.
        let list = GTLRDriveQuery_FilesList.query()
        list.spaces = "drive"
        list.q = "'\(folderID)' in parents and name='\(name)' and trashed=false"
        list.pageSize = 1
        
        service.executeQuery(list) { (_, result, error) in
            if let error = error {
                log.d(error.localizedDescription)
                Toast.show("백업 실패ㅜ")
                self.loadingStop()
                return
            }
            
            let fileList = result as? GTLRDrive_FileList
            let existingId = fileList?.files?.first?.identifier
            
            let file = GTLRDrive_File()
            file.name = name
            file.parents = [folderID]
            
            let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
            
            let query: GTLRDriveQuery
            if let existingId = existingId {
                query = GTLRDriveQuery_FilesUpdate.query(withObject: file, fileId: existingId, uploadParameters: uploadParameters)
            } else {
                query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
            }
            
            service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
                log.d(totalBytesUploaded)
                log.d(totalBytesExpectedToUpload)
            }
            
            DispatchQueue.main.async {
                service.executeQuery(query) { (_, result, error) in
                    if let unwrappedError = error {
                        Toast.show("백업 실패ㅜ")
                        self.loadingStop()
                        log.d(unwrappedError.localizedDescription)
                    }
                    else {
                        Toast.show("백업 성공!")
                        self.loadingStop()
                        log.d(result.debugDescription)
                    }
                }
            }
        }
    }

    
    func getAndSaveFileromGoogle() {
        ensureGoogleDriveAuthorized { ok in
            if !ok {
                Toast.show("구글 Drive 권한이 필요해요.")
                self.fileRecovery()
                return
            }
            
            // 1) Find our folder first.
            guard let googleUser = self.googleUser else {
                self.fileRecovery()
                return
            }
            
            self.getFolderID(name: BackupFileName.driveFolder, service: self.googleDriveService, user: googleUser) { folderId in
                guard let folderId = folderId, !folderId.isEmpty else {
                    self.fileRecovery()
                    return
                }
                
                // 2) List files only inside the folder.
                let query = GTLRDriveQuery_FilesList.query()
                query.spaces = "drive"
                query.pageSize = 100
                query.fields = "files(id,name,modifiedTime,size)"
                query.orderBy = "modifiedTime desc"
                query.q = "'\(folderId)' in parents and trashed=false"
                
                self.googleDriveService.executeQuery(query) { (_, files, error) in
                    if let error = error {
                        log.d(error.localizedDescription)
                        self.fileRecovery()
                        return
                    }
                    
                    guard
                        let list = files as? GTLRDrive_FileList,
                        let driveFiles = list.files,
                        !driveFiles.isEmpty
                    else {
                        self.fileRecovery()
                        return
                    }
                    
                    // pick latest for each expected file name
                    var chosen: [String: GTLRDrive_File] = [:]
                    for file in driveFiles {
                        guard let name = file.name, BackupFileName.all.contains(name) else { continue }
                        if chosen[name] == nil {
                            chosen[name] = file
                        }
                    }
                    
                    // Need at least realm to consider restore meaningful.
                    guard let realmFile = chosen[BackupFileName.realm], let realmId = realmFile.identifier else {
                        self.fileRecovery()
                        return
                    }
                    
                    self.ensureAppSupportDirectoryExists()
                    
                    // Download realm first, then CoreData pieces.
                    self.downloadDriveFile(fileId: realmId) { realmData in
                        guard let realmData = realmData else {
                            self.fileRecovery()
                            return
                        }
                        
                        do {
                            try realmData.write(to: self.documentsURL(BackupFileName.realm), options: .atomic)
                        } catch {
                            log.d(error.localizedDescription)
                            self.fileRecovery()
                            return
                        }
                        
                        // CoreData restore is optional: only if sqlite exists in drive folder.
                        let sqliteId = chosen[BackupFileName.coreDataSQLite]?.identifier
                        let walId = chosen[BackupFileName.coreDataSQLiteWAL]?.identifier
                        let shmId = chosen[BackupFileName.coreDataSQLiteSHM]?.identifier
                        
                        if sqliteId == nil {
                            // realm-only restore
                            self.reloadAllViewControllers()
                            return
                        }
                        
                        self.downloadDriveFile(fileId: sqliteId!) { sqliteData in
                            guard let sqliteData = sqliteData else {
                                self.fileRecovery()
                                return
                            }
                            
                            let backupSQLite = self.documentsURL(BackupFileName.coreDataSQLite)
                            let backupWAL = self.documentsURL(BackupFileName.coreDataSQLiteWAL)
                            let backupSHM = self.documentsURL(BackupFileName.coreDataSQLiteSHM)
                            
                            do { try sqliteData.write(to: backupSQLite, options: .atomic) } catch {
                                log.d(error.localizedDescription)
                                self.fileRecovery()
                                return
                            }
                            
                            let group = DispatchGroup()
                            var walData: Data?
                            var shmData: Data?
                            
                            if let walId = walId {
                                group.enter()
                                self.downloadDriveFile(fileId: walId) { data in
                                    walData = data
                                    group.leave()
                                }
                            }
                            if let shmId = shmId {
                                group.enter()
                                self.downloadDriveFile(fileId: shmId) { data in
                                    shmData = data
                                    group.leave()
                                }
                            }
                            
                            group.notify(queue: .main) {
                                do {
                                    if let walData = walData { try walData.write(to: backupWAL, options: .atomic) }
                                    if let shmData = shmData { try shmData.write(to: backupSHM, options: .atomic) }
                                } catch {
                                    log.d(error.localizedDescription)
                                    self.fileRecovery()
                                    return
                                }
                                
                                if UserDefaults.standard.bool(forKey: "useICloud") {
                                    self.restoreCoreDataStoreFromBackup(backupSQLite: backupSQLite, backupWAL: backupWAL, backupSHM: backupSHM)
                                } else {
                                    self.reloadAllViewControllers()
                                }
                            }
                        }
                    }
                }
            }
        }
  }

    private func downloadDriveFile(fileId: String, completion: @escaping (Data?) -> Void) {
        let mediaQuery = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileId)
        googleDriveService.executeQuery(mediaQuery) { (_, file, error) in
            if let error = error {
                log.d(error.localizedDescription)
                completion(nil)
                return
            }
            guard let data = (file as? GTLRDataObject)?.data else {
                completion(nil)
                return
            }
            completion(data)
        }
    }
    
    private func restoreCoreDataStoreFromBackup(backupSQLite: URL, backupWAL: URL, backupSHM: URL) {
        ensureAppSupportDirectoryExists()
        
        // Try to restore into the actual current store URL if available.
        let coordinator = persistenContainer.persistentStoreCoordinator
        let currentStoreURL = coordinator.persistentStores.first?.url ?? appSupportURL(BackupFileName.coreDataSQLite)
        let storeDir = currentStoreURL.deletingLastPathComponent()
        let destSQLite = currentStoreURL
        let destWAL = storeDir.appendingPathComponent(BackupFileName.coreDataSQLiteWAL)
        let destSHM = storeDir.appendingPathComponent(BackupFileName.coreDataSQLiteSHM)
        
        // Remove loaded stores before replacing.
        for store in coordinator.persistentStores {
            try? coordinator.remove(store)
        }
        
        do {
            // Replace main sqlite
            try coordinator.replacePersistentStore(
                at: destSQLite,
                destinationOptions: nil,
                withPersistentStoreFrom: backupSQLite,
                sourceOptions: nil,
                ofType: NSSQLiteStoreType
            )
            
            // Copy sidecar files if present
            if FileManager.default.fileExists(atPath: backupWAL.path) {
                try? FileManager.default.removeItem(at: destWAL)
                try FileManager.default.copyItem(at: backupWAL, to: destWAL)
            }
            if FileManager.default.fileExists(atPath: backupSHM.path) {
                try? FileManager.default.removeItem(at: destSHM)
                try FileManager.default.copyItem(at: backupSHM, to: destSHM)
            }
            
            // Reload persistent stores
            persistenContainer.loadPersistentStores { _, error in
                if let error = error {
                    log.d(error.localizedDescription)
                    self.fileRecovery()
                    return
                }
                self.reloadAllViewControllers()
            }
        } catch {
            log.d(error.localizedDescription)
            fileRecovery()
        }
    }
    
    func fileRecovery(){
          Toast.show("복원 실패ㅜ")
          loadingStop()
    }
    
    /* ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ IClude ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ */
    
    func setData(completion: (() -> Void)? = nil) {
        let container = NSPersistentCloudKitContainer(name: "DayModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                log.d("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        self.persistenContainer = container
        self.persistenContainer.viewContext.automaticallyMergesChangesFromParent = true
        
        if let completion = completion {
            completion()
            self.loadingStop()
        }
    }
    
    
    func reloadAllViewControllers() {
        let storyboard = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.storyboard
        let id = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.value(forKey: "storyboardIdentifier")
        let rootVC = storyboard?.instantiateViewController(withIdentifier: id as! String)
        UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController = rootVC
        App.module.presenter.addSubview(.visibleView, type: BackUpView.self){ view in
        }
        self.loadingStop()
        Toast.show("복원 성공!")
    }
    
    

    func setLottieImage(){
        let animation = LottieAnimation.named("ani_catchop_loader", subdirectory: "LottieImage")
        self.lottieAnimation.animation = animation
        
        self.lottieAnimation.frame = self.lottie_view.bounds
        self.lottie_view.addSubview(self.lottieAnimation)
    }
    
    
    func loadingStart(){
        DispatchQueue.main.async {
            self.loading_view.isHidden = false
            self.lottieAnimation.play()
        }
    }
    
    func loadingStop(){
        DispatchQueue.main.async {
            self.loading_view.isHidden = true
            self.lottieAnimation.stop()
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /* ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ Disable ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ */
    
    
    
    // 저장된 데이터로 복구하기     //지금은 폰 파일에서 불러오는중 구글에서 000복원가져오기
    // 된다
     func restoreFromStore(){
        //resetAllRecords()
        
        let storeFolderUrl = FileManager.default.urls(for: .applicationSupportDirectory, in:.userDomainMask).first!
        let storeUrl = storeFolderUrl.appendingPathComponent("DayModel.sqlite")
        let backUpFolderUrl = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask).first!
        let backupUrl = backUpFolderUrl.appendingPathComponent("DayModel" + ".sqlite")

        persistenContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            let stores = self.persistenContainer.persistentStoreCoordinator.persistentStores

            for store in stores {
                //print(store)
            }
            do{
                try self.persistenContainer.persistentStoreCoordinator.replacePersistentStore(at: storeUrl,destinationOptions: nil,withPersistentStoreFrom: backupUrl,sourceOptions: nil,ofType: NSSQLiteStoreType)
            } catch {
                print("Failed to restore")
            }
        })
     }

    
    
    
    //기존 데이터 삭제
    func resetAllRecords() {
        let context = persistenContainer.viewContext
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Day")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        do {
            try context.execute(deleteRequest)
            try context.save()
        }
        catch {
            print ("There was an error")
        }
    }
    
}

