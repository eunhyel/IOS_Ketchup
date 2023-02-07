//
//  Toast.swift
//  iosWork
//
//  Copyright © 2019 Inforex. All rights reserved.
//

import Foundation
import Toast_Swift


public class Toast : NotifyDelegate{

    class func showOnNavigation(_ message : String, duration : Double = 3.0, position : ToastPosition = .center, title : String? = nil, image: UIImage? = nil, completion: ((Bool)->Void)? = nil){
        self.navigationController?.view.clearToastQueue()
        var style = ToastStyle()
        style.titleAlignment = .center
        style.messageAlignment = .center
        style.horizontalPadding = 20
        self.navigationController?.view.makeToast(message, duration: duration, position: position, title: title, image: image, style: style, completion: completion)
    }
    
    class func show(_ message : String,
                    on: Presenter.OnController = .visibleView,
                    duration : Double = 2.0,
                    position : ToastPosition = .center,
                    background : UIColor = UIColor.black.withAlphaComponent(0.8),
                    title : String? = nil,
                    image: UIImage? = nil,
                    completion: ((Bool)->Void)? = nil){
        
        var style = ToastStyle()
        style.backgroundColor = background
        style.titleAlignment = .center
        style.messageAlignment = .center
        style.horizontalPadding = 20
        //style.verticalPadding = 60
        guard let vc = App.module.presenter.onViewController(on) else{
             return
         }
                
        vc.view.hideAllToasts()
        vc.view.clearToastQueue()
        
        vc.view.makeToast(message,
                          duration: duration,
                          position: position,
                          title: title,
                          image: image,
                          style: style,
                          completion: completion)
    }
   
}
