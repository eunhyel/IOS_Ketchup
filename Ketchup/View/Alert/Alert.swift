//
//  BCAlert.swift
//  iosClubRadio
//
//  Created by cschoi724 on 2020/04/08.
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation


class AlertAction {
    var title : String = ""
    var action : (() -> Void) = {}
    
    init(title : String = "", action : (()->Void)? = nil) {
        self.title = title
        if let doit = action {
            self.action = doit
        }else{
            self.action = {}
        }
    }
}

class Alert {
    
    static func message(_ title : String, leftAction: (()->Void)? = nil, rightAction: (()->Void)? = nil){
        App.module.presenter.addSubview(.visibleView, type: CustomAlertView.self){ view in
            view.message = title
            if let action = leftAction{
                view.leftAction = action
            }
            
            if let action = rightAction{
                view.rightAction = action
            }
        }
    }
    
    static func message(_ title : String, leftAction: AlertAction, rightAction: AlertAction){
        App.module.presenter.addSubview(.visibleView, type: CustomAlertView.self){ view in
            view.message = title
            if !leftAction.title.isEmpty {
                view.leftText = leftAction.title
            }
            
            if !rightAction.title.isEmpty {
                view.rightText = rightAction.title
            }
            
            view.leftAction = leftAction.action
            view.rightAction = rightAction.action
        }
    }
    
    static func message(_ title : NSMutableAttributedString, leftAction: AlertAction, rightAction: AlertAction){
        App.module.presenter.addSubview(.visibleView, type: CustomAlertView.self){ view in
            view.attributeText = title
            if !leftAction.title.isEmpty {
                view.leftText = leftAction.title
            }
            
            if !rightAction.title.isEmpty {
                view.rightText = rightAction.title
            }
            
            view.leftAction = leftAction.action
            view.rightAction = rightAction.action
        }
    }
    
    
}
