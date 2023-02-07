//
//  Write+func.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/26.
//

import Foundation
import SwiftyJSON

extension WriteView {

    /*
     사진 열기
     */
    func openPhoto() {
        picker.setDidFinish{ image in
            self.photo_imageView.image = image
            self.isImageEdit = true
            self.photo_btn.setImage(UIImage(named: ""), for: .normal)
        }
        
        picker.open()
    }
    
    
    
    /*
     이미지 업로드
     */
     func imageUpload(_ image: UIImage, _ name: String){
         ImageFileManager.shared
           .saveImage(image: image, name: name) { [] onSuccess in
            log.d("saveImage onSuccess: \(onSuccess)")
         }
     }
    
    
    
    /*
     인스타로 공유
     */
    func instreamGo(){
        let height = self.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        let imageY = 82 + height
        let imageSize = CGRect(x: 0, y: CGFloat(-imageY), width: self.frame.width, height: self.frame.height + 30)

        let totalSize = CGSize(width: frame.size.width, height: write_view.frame.height + 30)
        UIGraphicsBeginImageContextWithOptions(totalSize, false, UIScreen.main.scale)
        self.drawHierarchy(in: imageSize, afterScreenUpdates: true)
                
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let storiesUrl = URL(string: "instagram-stories://share") {
            if UIApplication.shared.canOpenURL(storiesUrl) {
            // 위의 sharingImageView의 image를 image에 저장
                guard let image = image else { return }
                // 지원되는 형식에는 JPG,PNG 가 있다.
                guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }
                let pasteboardItems: [String: Any] = [
                    //"com.instagram.sharedSticker.backgroundImage": imageData,
    
                    "com.instagram.sharedSticker.stickerImage": imageData,
                    // 배경 값 : 두 값이 다르면 그래디언트를 생성
                    "com.instagram.sharedSticker.backgroundTopColor": "#F2ECDF",
                    "com.instagram.sharedSticker.backgroundBottomColor": "#F2ECDF"
                    
                ]
                let pasteboardOptions = [
                    UIPasteboard.OptionsKey.expirationDate: Date().addingTimeInterval(300)
                ]
                UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
                UIApplication.shared.open(storiesUrl, options: [:], completionHandler: nil)
            } else {
                Toast.show("인스타그램이 설치되지 않았습니다.")
                print("User doesn't have instagram on their device.")
            }
        }
    }
    
    
    
    
    /*
     이미지 사이즈 조절
     */
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width // 새 이미지 확대/축소 비율
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
