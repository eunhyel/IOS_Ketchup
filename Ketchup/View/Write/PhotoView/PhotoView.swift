//
//  PhotoView.swift
//  iosClubRadio
//

import UIKit
import SwiftyJSON
import RxCocoa
import RxSwift

class PhotoView : XibView{
    
    @IBOutlet weak var another_view: UIView!
    @IBOutlet weak var photos_imageView: UIImageView!
    @IBOutlet weak var left_btn: UIButton!
    @IBOutlet weak var right_btn: UIButton!
    @IBOutlet weak var close_btn: UIButton!
    
    let bag = DisposeBag()
    var data : JSON!
    
    var pageNo = 0
    var imageName = ""
    var current_page = 0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            initialize()
            isInitailized = false
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
    }
    
    func initialize(){
        setLayout()
        setView()
        bind()
    }
    
    func setLayout(){
        swipeRight.isEnabled = false
        photos_imageView.layer.cornerRadius = 5
    }
    
    func setView(){
    }

    func bind(){
        let without = UITapGestureRecognizer()
        another_view.addGestureRecognizer(without)
        
        left_btn.rx.tap
            .bind { (_) in
            }.disposed(by: bag)
        
        right_btn.rx.tap
            .bind { (_) in
            }.disposed(by: bag)
        
        close_btn.rx.tap
            .bind { (_) in
                self.removeFromSuperview()
            }.disposed(by: bag)
        
        without.rx.event
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .bind { _ in
                self.removeFromSuperview()
            }
            .disposed(by: bag)
    }
}
