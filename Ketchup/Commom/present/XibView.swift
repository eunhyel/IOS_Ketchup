//
//  XibView.swift
//  iosYeoboya
//
//  Created by cschoi724 on 2019/10/25.
//  Copyright © 2019 Inforex. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

/**
 * XibView 기본형
 */
class XibView: UIView {
    var viewData : JSON = JSON()
    var isInitailized = true
    var apearViewListener : (() -> Void)? = nil
    var removeViewListener : (() -> Void)? = nil
    var swipeRight : UISwipeGestureRecognizer!
    
    required init(frame: CGRect, viewData : JSON) {
        super.init(frame: frame)
        self.viewData = viewData
        self.tag = 555
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
        self.swipeRecognizer()
        self.tag = 555
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
        self.swipeRecognizer()
        self.tag = 555
    }

    private func commonInit(){
        guard let xibName = NSStringFromClass(self.classForCoder).components(separatedBy: ".").last else { return }
        if let view = Bundle.main.loadNibNamed(xibName, owner: self, options: nil)?.first as? UIView{
            view.frame = self.bounds
            view.autoresizingMask = [.flexibleHeight,.flexibleWidth]
            self.addSubview(view)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let listender = apearViewListener, isInitailized{
            listender()
        }
    }
    
    override func removeFromSuperview() {
        if swipeRight.isEnabled {
            UIView.animate(withDuration: Global.removAniTime, animations: {
                self.frame.origin.x = UIScreen.main.bounds.width
            }, completion: { _ in
                super.removeFromSuperview()
                if let listender = self.removeViewListener {
                    listender()
                }
            })
        }
        else {
            super.removeFromSuperview()
            if let listender = self.removeViewListener {
                listender()
            }
        }
    }
    
    func swipeRecognizer() {
            swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture(_:)))
            swipeRight.direction = UISwipeGestureRecognizer.Direction.right
            self.addGestureRecognizer(swipeRight)
            
        }
        
        @objc func respondToSwipeGesture(_ gesture: UIGestureRecognizer){
            if let swipeGesture = gesture as? UISwipeGestureRecognizer {
                switch swipeGesture.direction{
                case UISwipeGestureRecognizer.Direction.right:
                    removeFromSuperview()
                    break
                default: break
                }
            }
        }
    
    func terminate(_ completion : (() -> Void)? = nil){ }
}
