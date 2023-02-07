//
//  PhotosPermission.swift
//  iosYeoboya
//
//  Copyright © 2019 Inforex. All rights reserved.
//

import Foundation
import Photos
import UIKit

protocol PhotosPermission{}
extension PhotosPermission{
    
    /**
     * 사진 권한 요청
     *********************************************/
    static func requestAuthorizationPhotos(_ completion : ((Bool) -> Void)? = nil){
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
            if let completion = completion{
                if status == .authorized { completion(true) }
                else{ completion(false) }
            }
        })
    }
    
    func requestAuthorizationPhotos(_ completion : ((Bool) -> Void)? = nil){
        PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
            if let completion = completion{
                if status == .authorized { completion(true) }
                else{ completion(false) }
            }
        })
    }
    
    func requestManualyAuthorization(cancel : (() -> Void)? = nil){
        DispatchQueue.main.async {
            Alert.message("앨범에 저장된 사진을 등록하기 위해서는 [사진]권한 설정이 필요합니다.\n설정>앱 권한에서 [사진]을 켜주세요", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                if let url = URL(string: UIApplication.openSettingsURLString){
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }))
        }
    }
}
