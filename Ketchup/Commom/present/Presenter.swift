//
//  present.swift
//  iosWork
//
//  Created by cschoi724 on 11/03/2019.
//  Copyright © 2019 Inforex. All rights reserved.
//

import UIKit

class Presenter : PresenterDelegate, PresentedView, PresentedTransfer {
    
    //현재 무슨 뷰인지 파악
    var contextView : XibView!
    var beforeView : XibView!   // 이전뷰

    enum OnController {
        case navigationView,visibleView,topView
    }
    
    var visibleViewController: UIViewController? {
        get{
            return visibleViewController()
        }
    }
    
    var navigationViewController : UINavigationController?{
        get{
            return navigationViewController()
        }
    }
    
    var topViewController : UIViewController?{
        get{
            return navigationTopViewController()
        }
    }
    
    func onViewController(_ on : OnController) -> UIViewController?{
        switch on {
        case .navigationView: return navigationViewController()
        case .visibleView: return visibleViewController()
        case .topView: return navigationTopViewController()
        }
    }
    
    
    
}

protocol PresenterDelegate {
    var visibleViewController : UIViewController? {get}
    var navigationViewController : UINavigationController? {get}
    var topViewController : UIViewController? {get}
    func onViewController(_ on : Presenter.OnController) -> UIViewController?
}

protocol PresentedView{}
extension PresentedView {
    ///현재의 보이는 뷰컨트롤러를 얻는 함수, 네비게이션이나 탭바에서도 접근할 수 있다
    fileprivate func visibleViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController?{
        
        if let nav = base as? UINavigationController{
            return visibleViewController(base:nav.visibleViewController)
        }
        if let tab = base as? UITabBarController{
            if let selected = tab.selectedViewController{
                return visibleViewController(base:selected)
            }
        }
        if let presented = base?.presentedViewController{
            return visibleViewController(base:presented)
        }
        return base
    }
    
    // 네비게션 뷰컨을 가져온다
    fileprivate func navigationViewController() -> UINavigationController?{
        return UIApplication.shared.keyWindow?.rootViewController as? UINavigationController
    }
    
    // 네비게이션 뷰컨의 탑뷰컨트롤러를 가져온다. 독립성을 위해 위의 함수를 사용하지 않음 ...연관 없다 싶으면 위의 함수를 호출해서 코드 줄여도 될듯
    fileprivate func navigationTopViewController() -> UIViewController?{
        return (UIApplication.shared.keyWindow?.rootViewController as? UINavigationController)?.topViewController
    }
    
}


