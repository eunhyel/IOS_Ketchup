//
//  CustomAlertView.swift

//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import RxSwift

class CustomAlertView : XibView {
    
    @IBOutlet weak var super_view: UIView!
    @IBOutlet weak var message_label: UILabel!
    @IBOutlet weak var left_btn: UIButton!
    @IBOutlet weak var right_btn: UIButton!
    
    var message : String = ""
    var attributeText : NSMutableAttributedString!
    var leftText : String = "아니오"
    var rightText : String = "예"
    var leftAction : () -> Void = {}
    var rightAction : () -> Void = {}
    var disposbag = DisposeBag()
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized{
            initialize()
            isInitailized = false
        }
    }
    
    func initialize(){
        swipeRight.isEnabled = false
        super_view.layer.cornerRadius = 40
        
        if !message.isEmpty {
            message_label.text = message
        }else if attributeText != nil{
            message_label.attributedText = attributeText
        }
        
        left_btn.setTitle(leftText, for: .normal)
        right_btn.setTitle(rightText, for: .normal)
        
        left_btn.rx.tap
            .bind { (_) in
                self.leftAction()
                self.removeFromSuperview()
            }
            .disposed(by: disposbag)
        
        right_btn.rx.tap
            .bind { (_) in
                self.rightAction()
                self.removeFromSuperview()
            }
            .disposed(by: disposbag)
    }
    
    func setAttributeText(_ attributeText : NSAttributedString){
        message_label.attributedText = attributeText
    }
}
