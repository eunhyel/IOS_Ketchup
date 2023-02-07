//
//  AppDelegate.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/18.
//

import UIKit
import FontBlaster
import CoreData
import GoogleSignIn
import Firebase
import CloudKit

let persistFontKey = "Cafe24Syongsyong"

extension Notification.Name{
    static let dataLoad = Notification.Name("dataLoad")
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var cloudStatus: Bool = true
    static var useCloudSync = UserDefaults.standard.bool(forKey: "useICloud")
    
    /*
     글씨체
     */
    lazy var Cafe24Syongsyong: AppFont = {
        let font = AppFont(plist: "Cafe24Syongsyong")
        return font
    }()
    
    lazy var RidiBatang: AppFont = {
        let font = AppFont(plist: "RidiBatang")
        return font
    }()
    
    lazy var NanumSquareOTFL: AppFont = {
        let font = AppFont(plist: "NanumSquareOTFL")
        return font
    }()
    
    lazy var KyoboHandwriting2019: AppFont = {
        let font = AppFont(plist: "KyoboHandwriting2019")
        return font
    }()

    lazy var Cafe24SSurround: AppFont = {
        let font = AppFont(plist: "Cafe24SSurround")
        return font
    }()
    
    lazy var Cafe24Ohsquareair: AppFont = {
        let font = AppFont(plist: "Cafe24-Ohsquareair")
        return font
    }()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        isICloudContainerAvailable()
        FirebaseApp.configure()
        //FirebaseApp.setValue("aa", forKey: "aa")
        
        
        //GIDSignIn.sharedInstance.clientID = "150068919703-frc9svv2ssrbni04kqb4e54b90021m15.apps.googleusercontent.com"
        
        FontBlaster.blast { fonts in
            //print(fonts)
        }
        //UIFont.printAllFonts()
        if let savedFont = UserDefaults.standard.string(forKey: persistFontKey) {
            switch savedFont {
            case Cafe24Syongsyong.familyName:
                FontManager.shared.currentFont = Cafe24Syongsyong
                break
            case RidiBatang.familyName:
                FontManager.shared.currentFont = RidiBatang
                break
            case NanumSquareOTFL.familyName:
                FontManager.shared.currentFont = NanumSquareOTFL
                break
            case KyoboHandwriting2019.familyName:
                FontManager.shared.currentFont = KyoboHandwriting2019
                break
            case Cafe24SSurround.familyName:
                FontManager.shared.currentFont = Cafe24SSurround
                break
            case Cafe24Ohsquareair.familyName:
                FontManager.shared.currentFont = Cafe24Ohsquareair
                break
            default:
                break
            }
        }
        else{
            FontManager.shared.currentFont = Cafe24Syongsyong
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    
    
    
    
    
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
          return GIDSignIn.sharedInstance.handle(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    
    
    func isICloudContainerAvailable(){
        CKContainer.default().accountStatus { (accountStatus, error) in
          if accountStatus == .available {
            //첫 시작이면 동기화 활성화
            if !UserDefaults.standard.bool(forKey: "isFirstStart")  {
                UserDefaults.standard.set(true, forKey: "useICloud")
            }
            self.cloudStatus = true
            print("iCloud app container and private database is available")
          } else {
            //첫 시작에 동기화 사용할수 없으면 비활성화
            if !UserDefaults.standard.bool(forKey: "isFirstStart")  {
                UserDefaults.standard.set(false, forKey: "useICloud")
            }
            self.cloudStatus = false
            print("iCloud not available \(String(describing: error?.localizedDescription))")
          }
        }
    }
}

