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
    
    func autoGoogleLogin(){
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        if GoogleSignIn.GIDSignIn.sharedInstance.hasPreviousSignIn() {
            GoogleSignIn.GIDSignIn.sharedInstance.restorePreviousSignIn() { signResult, error in
                guard let result = signResult else {
                    return
                }
                self.google_id_label.text = "ID \(result.profile?.email ?? "No email")"
                self.googleDriveService.authorizer = result.fetcherAuthorizer
                self.googleUser = result
            }
            isGoogleLogin = true
        }else {
            log.d("구글 로그인 한적이 없어서 한번은 해야함.")
        }
    }
    
    
    func googleLogin(){
        let additionalScopes = ["https://www.googleapis.com/auth/drive"]
        GIDSignIn.sharedInstance.signIn(withPresenting: getNavigationController(), hint: nil, additionalScopes: additionalScopes) { signResult, error in
            guard let result = signResult else {
                return
            }
            
            self.google_id_label.text = "ID \(result.user.profile?.email ?? "No email")"
            
            self.googleDriveService.authorizer = result.user.fetcherAuthorizer
            self.googleUser = result.user
        }
        isGoogleLogin = true
        
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
        let myFolderName = "Ketchup"
        
        guard let googleUser = googleUser else {
            return
        }
        
        getFolderID(name: myFolderName, service: googleDriveService, user: googleUser) {
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
    
    
    //2. 기본폴더 검색
    func getFolderID(name: String, service: GTLRDriveService, user: GIDGoogleUser, completion: @escaping (String?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.spaces = "drive"
        
        query.corpora = "user"
            
        let withName = "name = '\(name)'" // Case insensitive!
        let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
        let ownedByUser = "'\(user.profile!.email)' in owners"
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
        let reamlLocal = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask).first!
        let ramlmURL = reamlLocal.appendingPathComponent("default" + ".realm")
        
        uploadFile(name: "default.realm", folderID: uploadFolderID ?? "", fileURL: ramlmURL, mimeType: "application/x-realm", service: googleDriveService)
    }

    /*
     파일업로드
     */
    func uploadFile(name: String, folderID: String, fileURL: URL, mimeType: String, service: GTLRDriveService) {
        
        let file = GTLRDrive_File()
        file.name = name
        file.parents = [folderID]
        
        let uploadParameters = GTLRUploadParameters(fileURL: fileURL, mimeType: mimeType)
        
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
        
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

    
    func getAndSaveFileromGoogle() {
      let query = GTLRDriveQuery_FilesList.query()
      query.spaces = "drive"
      query.q = "trashed=false"
      self.googleDriveService.executeQuery(query) { (ticket, files, error) in
          if error == nil {
              if let files = files as? GTLRDrive_FileList {
                  if let driveFiles = files.files /*?? [GTLRDrive_File]()*/ {
                      if driveFiles.count > 0 {
                          for file in driveFiles {
                            if file.name == "DayModel.sqlite" || file.name == "default.realm"{
                                self.googleDriveService.executeQuery(GTLRDriveQuery_FilesGet.queryForMedia(withFileId: file.identifier!)) { (ticket, file, error) in
                                    guard let data = (file as? GTLRDataObject)?.data else {
                                        return
                                    }
                                    
                                    let reamlLocal = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask).first!
                                    let ramlmURL = reamlLocal.appendingPathComponent("default" + ".realm")
                                    
                                    let storeFolderUrl = FileManager.default.urls(for: .applicationSupportDirectory, in:.userDomainMask).first!
                                    let storeUrl = storeFolderUrl.appendingPathComponent("DayModel.sqlite")
                                    
                                    do {
                                        try data.write(to: ramlmURL, options: .atomic)
                                        
                                        if UserDefaults.standard.bool(forKey: "useICloud") {
                                            try data.write(to: storeUrl, options: .atomic)
                                            self.persistenContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
                                                let stores = self.persistenContainer.persistentStoreCoordinator.persistentStores

                                                for store in stores {
                                                    print(store)
                                                    print(self.persistenContainer)
                                                }
                                                
                                                do{
                                                    try self.persistenContainer.persistentStoreCoordinator.replacePersistentStore(at: storeUrl,destinationOptions: nil,withPersistentStoreFrom: storeUrl,sourceOptions: nil,ofType: NSSQLiteStoreType)
                                                } catch {
                                                    print("Failed to restore")
                                                }
                                            })
                                        }
                                        else {
                                            
                                        }
                                        self.reloadAllViewControllers()
                                    }
                                    catch {
                                        self.fileRecovery()
                                        print(error.localizedDescription)
                                    }
                                }
                              }
                          }
                      }
                      else {
                        self.fileRecovery()
                          print("No back up file found")
                      }
                  }
                  else {
                    self.fileRecovery()
                      print("No back up file found")
                  }
              }
              else {
                self.fileRecovery()
                  print("Something went wrong")
              }
          }
          else {
            self.fileRecovery()
              print("Something went wrong")
          }
        
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

