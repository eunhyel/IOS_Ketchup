//
//  PresenterTransfer.swift
//  iosYeoboya
//
//  Created by cschoi724 on 17/09/2019.
//  Copyright © 2019 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit
/*
 * *ios에서의 화면 전환 개념*
 * 1. 뷰 컨트롤러의 뷰 위에 다른 뷰를 가져와 바꿔치기하기
 * 2. 뷰 컨트롤러에서 다른 뷰 컨트롤러를 호출하여 화면 전환하기
 * 3. 내비게이션 컨트롤러를 사용하여 화면 전환하기
 * 4. 화면 전환용 객체 세그웨이를 사용하여 화면 전환하기
 */
typealias DataHandling<T> = (inout T) -> Void
protocol PresentedTransfer where Self : PresenterDelegate {}
extension PresentedTransfer  {

    /*
     * [Create]
     * - 스토리보드에서 뷰컨트롤러를 만들어 반환
     * - 스토리보드 이름 값의 유무를 분기해 뷰 컨트롤러를 생성
     * storyBoardName : 스토리보드의 이름
     * withIdentifier : 스토리보드 안에서의 viewcontroller 호출 아이디
     */
    func createViewController<T>(_ storyBoardName : String? = nil, withIdentifier : String) -> T?{
        if let name = storyBoardName {
            let storyBoard = UIStoryboard(name: name, bundle: nil)
            return storyBoard.instantiateViewController(withIdentifier: withIdentifier) as? T
        }else{
            return self.visibleViewController?.storyboard?.instantiateViewController(withIdentifier: withIdentifier) as? T
        }
    }
 
    
    /**
     * [addSubview]
     * - 지정한 viewController 에서 UIView를 addSubview 한다
     * - 데이터 전달 시 뷰 객체 '생성' 타이밍에 데이터가 없으니 주의
     * on : xibView 가 생성될 위치를 결정 ( navigationView. visibleview, topview)
     * type : 생성할 xibView view 의 class 이름
     * frame : 생성할 xibView frame, 기본은 UIScreen.main.bounds
     * dataHandling : 생성한 UIView 에 값 전달
     * Return -> 생성한 UIView
     */
    @discardableResult
    func addSubview<T : UIView>(_ on : Presenter.OnController,
                                 type : T.Type,
                                 frame : CGRect = UIScreen.main.bounds,
                                 dataHandling : DataHandling<T>? = nil) -> UIView{
        var view : T = T(frame: frame)
        if let handling = dataHandling{ handling(&view) }
        
        guard let vc = self.onViewController(on) else{
            return view
        }
        
        view.center = vc.view.center
        vc.view.addSubview(view)
        return view
    }
    
    /**
     * [addSubviewPre]
     *  선행조건 추가
     *  precedence 값이 있으면 동기적으로 precedence 를 먼저 선행하고 서브뷰 한다
     *   순서 : 생성 -> 데이터 전달 -> 서브뷰
     *  precedence 를 넣을 시 반드시 completion 클로저를 실행해줘야한다
     */
    func addSubviewPre<T : UIView>(_ on : Presenter.OnController,
                                 type : T.Type,
                                 frame : CGRect = UIScreen.main.bounds,
                                 precedence : ((inout T, @escaping (() -> Void)) -> Void)? = nil){
        var view : T = T(frame: frame)
        if let handling = precedence{
            handling(&view){
                if let vc = self.onViewController(on) {
                    view.center = vc.view.center
                    vc.view.addSubview(view)
                }
            }
        }else{
            if let vc = self.onViewController(on) {
                view.center = vc.view.center
                vc.view.addSubview(view)
            }
        }
    }
    
    /**
     * [addSubview] : XibView 버전
     * - 지정한 viewController 에서 UIView를 addSubview 한다
     * - viewData 데이터를 통한 전달 시 뷰 객체 '생성' 타이밍에 데이터가 존재한다
     *   데이터 전달 타이밍에 따라 dataHandling 을 사용할 수 있다
     * on : xibView 가 생성될 위치를 결정 ( navigationView. visibleview, topview)
     * type : 생성할 xibView view 의 class 이름
     * frame : 생성할 xibView frame, 기본은 UIScreen.main.bounds
     * viewData : 생성타이밍에 전달할 데이터
     * dataHandling : 생성한 UIView 에 값 전달
     * Return -> 생성한 UIView
     */
    @discardableResult
    func addSubview<T : XibView>(_ on : Presenter.OnController,
                                 type : T.Type,
                                 frame : CGRect = UIScreen.main.bounds,
                                 viewData: JSON = JSON(),
                                 dataHandling : DataHandling<T>? = nil) -> XibView{
        var view : T = T(frame: frame,viewData: viewData)
        if let handling = dataHandling{ handling(&view) }
        
        guard let vc = self.onViewController(on) else{
            return view
        }
        
        view.center = vc.view.center
        vc.view.addSubview(view)
        return view
    }
    
    
    /**
     * [addSubviewPre] : XibView 버전
     *  설명및 구조가 위 함수들과 동일함
     */
    func addSubviewPre<T : XibView>(_ on : Presenter.OnController,
                                 type : T.Type,
                                 frame : CGRect = UIScreen.main.bounds,
                                 viewData: JSON = JSON(),
                                 precedence : ((inout T, @escaping (() -> Void)) -> Void)? = nil) {
        var view : T = T(frame: frame,viewData: viewData)
        if let handling = precedence{
            handling(&view){
                if let vc = self.onViewController(on) {
                    view.center = vc.view.center
                    vc.view.addSubview(view)
                }
            }
        }else{
            if let vc = self.onViewController(on) {
                view.center = vc.view.center
                vc.view.addSubview(view)
            }
        }
    }
    
    /*
     * [Present]
     * - 뷰컨이 다른 뷰컨을 호출해 이동하는 기본형
     * - 이동 할 뷰 컨트롤러에 데이터를 넘겨줄 필요가 있다면 dataHandling 를 이용해 넘겨준다
     * - 넘겨 줄 데이터가 없다면 withIdentifier 넣고 사용하면 된다
     * storyBoardName : 스토리보드의 이름
     * withIdentifier : 스토리보드 안에서의 viewcontroller 호출 아이디
     * type           : 제네릭타입 추론을 위해 실제로 사용하지 않지만 넘겨준다
     * animated       : 이동시 애니매이션 여부
     * completion     : 완료 핸들러
     * dataHandling   : 생성한 viewcontroller 에 값 저장(이동 할 뷰컨트롤러에 값 넘겨줄때 사용)
     */
    func present<T : UIViewController>(_ storyBoardName : String? = nil, withIdentifier : String, origin : UIViewController? = nil,
                                       type: T.Type ,animated : Bool = true, completion : (() -> Void)? = nil, dataHandling : DataHandling<T>? = nil){
        if var viewController : T = createViewController(storyBoardName, withIdentifier: withIdentifier){
            if let handling = dataHandling{  handling(&viewController) }
            viewController.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            if let originViewController = origin {
                originViewController.present(viewController, animated: animated, completion: completion)
            }else{
                guard let navi = self.navigationViewController else { return }
                navi.present(viewController, animated: animated, completion: completion)
            }
        }
    }
    
    /*
     * [Present]
     * - 뷰컨이 다른 뷰컨을 호출해 이동하는 기본형
     * - 이동 할 뷰 컨트롤러에 데이터를 넘겨줄 필요가 있다면 dataHandling 를 이용해 넘겨준다
     * - 넘겨 줄 데이터가 없다면 withIdentifier 넣고 사용하면 된다
     * viewController : 이동할 뷰컨트롤러
     * animated       : 이동시 애니매이션 여부
     * completion     : 완료 핸들러
     */
    func present<T : UIViewController>(_ viewController : T, animated : Bool = true, completion : (() -> Void)? = nil){
        self.visibleViewController?.present(viewController, animated: animated, completion: completion)
    }

    
    /*
     * [Push]
     * - navigationController 의 root view 에 push 하는 방식으로 이동
     * - 이동 할 뷰 컨트롤러에 데이터를 넘겨줄 필요가 있다면 dataHandling 를 이용해 넘겨준다
     * - 넘겨 줄 데이터가 없다면 withIdentifier 넣고 사용
     * storyBoardName : 스토리보드의 이름
     * withIdentifier : 스토리보드 안에서의 viewcontroller 호출 아이디
     * type           : 제네릭타입 추론을 위해 실제로 사용하지 않지만 넘겨준다
     * animated       : 이동시 애니매이션 여부
     * dataHandling   : 생성한 viewcontroller 에 값 저장(이동 할 뷰컨트롤러에 값 넘겨줄때 사용)
     */
    func pushViewController<T : UIViewController>(_ storyBoardName : String? = nil, withIdentifier : String, type : T.Type, animated : Bool = true, dataHandling : DataHandling<T>? = nil){
        if var viewController : T = createViewController(storyBoardName, withIdentifier: withIdentifier){
            if let handling = dataHandling{  handling(&viewController) }
            if let navigationController = self.visibleViewController?.navigationController {
                navigationController.pushViewController(viewController, animated: animated)
            }
        }
    }
    
    /*
     * [PopAndPush]
     * -  지정한 뷰컨트롤러로 이동하면서 팝업뷰를 닫는다
     * storyBoardName : 스토리보드의 이름
     * withIdentifier : 스토리보드 안에서의 viewcontroller 호출 아이디
     * type           : 제네릭타입 추론을 위해 실제로 사용하지 않지만 넘겨준다
     * animated       : 이동시 애니매이션 여부
     * dataHandling   : 생성한 viewcontroller 에 값 저장(이동 할 뷰컨트롤러에 값 넘겨줄때 사용)
     */
    func popToViewController<T : UIViewController>(_ storyBoardName : String? = nil, withIdentifier : String, type : T.Type, animated : Bool = true, dataHandling : DataHandling<T>? = nil){
        if var viewController : T = createViewController(storyBoardName, withIdentifier: withIdentifier){
            if let handling = dataHandling{  handling(&viewController) }
            if let navigationController = self.visibleViewController?.navigationController {
                navigationController.popToViewController(viewController, animated: animated)
            }
        }
    }
    
    /*
     *  [Pop]
     * - 이전 푸시했던 뷰컨트롤러를 팝, 이전 뷰컨트롤로가 최상위로 올라온다
     *   animated : 이동시 애니매이션 여부
     */
    func popViewController(animated: Bool = true){
        if let viewController = visibleViewController{
            if let navigationController = viewController.navigationController {
                navigationController.popViewController(animated: animated)
            }
        }
    }
    
    /*
     *  [AllPop]
     * - 모든 뷰컨을 닫는다
     *   animated : 이동시 애니매이션 여부
     */
    func popRootViewController(animated: Bool = true){
        if let viewController = visibleViewController{
            if let navigationController = viewController.navigationController {
                navigationController.popToRootViewController(animated: animated)
            }
        }
    }
    
}
