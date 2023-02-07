//
//  PhotoLibrary.swift
//  HelperKit
//
//  Copyright © 2019 Inforex. All rights reserved.
//

import Foundation
import UIKit
import CoreServices
import CropViewController
import Photos

class PhotoLibrary : NSObject, UIImagePickerControllerDelegate,UINavigationControllerDelegate, PhotosPermission, TOCropViewControllerDelegate{
    static let sharedInstance: PhotoLibrary = { return PhotoLibrary() }()
    fileprivate var didFinish : ((UIImage) -> Void) = {_ in}
    fileprivate var didFinishWithData : ((Data) -> Void) = {_ in
        Toast.show("JPG,PNG형식의 파일만 등록 가능합니다.")
    }
    fileprivate var cancel : (() -> Void)?
    let picker = UIImagePickerController()
    
    public func open(_ sourceType: UIImagePickerController.SourceType = .photoLibrary){
        requestAuthorizationPhotos{ allow in
            guard allow else {                
                self.requestManualyAuthorization()
                return
            }
            DispatchQueue.main.async {
                if UIImagePickerController.isSourceTypeAvailable(sourceType){
                    self.picker.sourceType = sourceType
                    self.picker.delegate = self
                    self.picker.mediaTypes = [kUTTypeImage as String, kUTTypeGIF as String]
                    //self.picker.allowsEditing = true
                    self.picker.modalPresentationStyle = .fullScreen
                    
                    App.module.presenter.visibleViewController?.present(self.picker, animated: true)
                }
            }
        }
    }
        
    func setDidFinish(_ handler : @escaping ((UIImage) -> Void)){
        self.didFinish = handler
    }
    
    func setDidFinishWithData(_ handler : @escaping ((Data) -> Void)){
        self.didFinishWithData = handler
    }
    
    func setCancel(_ handler : (() -> Void)?){
        self.cancel = handler
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {        
        if let completion = self.cancel {
            completion()
        }
        picker.dismiss(animated: false)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        App.module.presenter.visibleViewController?.dismiss(animated: true){
            if let phAsset = info[.phAsset] as? PHAsset{
                let options = PHImageRequestOptions()
                options.isSynchronous = true
                //options.resizeMode = .fast
                PHImageManager.default().requestImageData(for: phAsset, options: options) { (imageData, UTI, orientation, info) in
                    if let data = imageData, let uti = UTI{
                        if UTTypeConformsTo(uti as CFString, kUTTypeGIF){
                            self.didFinishWithData(data)
                        }else{
                            if let image = UIImage(data: data){
                                self.ToCropView(image)
                            }
                        }
                    }
                }
            } else if let image = info[.originalImage] as? UIImage { // 카메라로 찍을 경우
                self.ToCropView(image)
            }
        }
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int){
        cropViewController.dismiss(animated: true) { () -> Void in
            self.didFinish(image)
        }
    }


    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool){
        cropViewController.dismiss(animated: true) { () -> Void in  }
    }
    
    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
        
    func ToCropView(_ image: UIImage){
        let crop = TOCropViewController(image: image)
        crop.delegate = self
        App.module.presenter.visibleViewController?.present(crop, animated: true)
    }
}




