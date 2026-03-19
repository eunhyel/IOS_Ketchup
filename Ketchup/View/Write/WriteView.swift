//
//  TalkRewardView.swift
//
//  Created by eunhye on 2020/12/10.
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift
import RxCocoa
import Kingfisher
import RealmSwift

enum Type {
    case view, write, edit
}

class WriteView: XibView{
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var expandView: UIView!
    @IBOutlet weak var delete_btn: UIButton!
    @IBOutlet weak var edit_btn: UIButton!
    @IBOutlet weak var close_btn: UIButton!
    @IBOutlet weak var photo_btn: UIButton!
    @IBOutlet weak var photo_imageView: UIImageView!
    @IBOutlet weak var daily_textView: UITextView!
    @IBOutlet weak var bar_view: UIView!
    @IBOutlet weak var write_view: UIView!
    @IBOutlet weak var view_bottom_constraint: NSLayoutConstraint!
    @IBOutlet weak var view_height_constraint: NSLayoutConstraint!
    @IBOutlet weak var instream_btn: UIButton!
    @IBOutlet weak var date_picker_view: UIDatePicker!
    @IBOutlet weak var date_view: UIView!
    @IBOutlet weak var date_constraint: NSLayoutConstraint!
    @IBOutlet weak var date_bottom_constraint: NSLayoutConstraint!
    @IBOutlet weak var photo_view: UIStackView!
    
    let picker = PhotoLibrary()
    var textModel = TextModel()
    
    var calendar = Calendar.current //켈린더 객체 생성
    var isKeyboard = false
    var isImageEdit = false
    
    var isType : Type = .view
    var imageData: Data?
    
    let realm = try! Realm()
    
    var items : DailyModel = DailyModel()
    weak var mainView : ViewController!
    
    let bag = DisposeBag()
    fileprivate var didFinish : ((UIImage, JSON, Date) -> Void) = {_,_,_   in}
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            isInitailized = false
            initialize()
        }
    }
    
    func initialize(){
        setView()
        bind()
        
        DispatchQueue.main.async {
            self.setShadow()
        }
    }
    
    func setShadow(){
        photo_view.layer.shadowColor = UIColor(r: 0, g: 0, b: 0, a: 0.2).cgColor
        photo_view.layer.shadowOpacity = 1
        photo_view.layer.shadowOffset = CGSize(width: 0, height: 0)
        photo_view.layer.shadowRadius = 4
        let bounds = photo_view.bounds
        let shadowPath = UIBezierPath(rect: CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: bounds.height)).cgPath
        photo_view.layer.shadowPath = shadowPath
        photo_view.layer.shouldRasterize = true
        photo_view.layer.rasterizationScale = UIScreen.main.scale
    }
    
    
    func setView(){
        self.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)
        
        var components = DateComponents()
        components.day = -25
        let minDate = Calendar.autoupdatingCurrent.date(byAdding: components, to: Date())
        //date_picker_view.minimumDate = minDate
        
        
        date_picker_view.maximumDate = Date()
  
        if #available(iOS 14.0, *) {
            date_constraint.constant = 5
            date_bottom_constraint.constant = 15
        }
        else {
            date_bottom_constraint.constant = 2
            date_constraint.constant = -10
        }
        
        if isType == .view{        //보기모드,수정
            date_view.isHidden = true
            instream_btn.setImage(UIImage(named: "btnHdInsta"), for: .normal)       //보기면 인스타
            bar_view.isHidden = true
            daily_textView.isEditable = false
            delete_btn.isHidden = false
            photo_btn.isHidden = true
            daily_textView.text = items.text
            date_picker_view.isHidden = true
            if items.imageData != nil {     //이미지 데이터가 있으면 이미지 데이터로
                self.photo_imageView.image = UIImage(data: self.items.imageData ?? Data())
            }
            else {      //이미지 데이터가 없으니 디폴트 이미지로
                 self.photo_imageView.image = UIImage(named: "img_dafault_0" + String(items.defaultImage))
            }
            daily_textView.textColor = UIColor(r: 48,g: 48,b: 48)
        }
        else if isType == .write{
            date_view.isHidden = false
            date_picker_view.isHidden = false
            edit_btn.isHidden = true
            instream_btn.setImage(UIImage(named: "btn_hd_write"), for: .normal)       //쓰기면 등록
            delete_btn.isHidden = true
            daily_textView.text = "내용을 입력하세요"
            daily_textView.textColor = UIColor(r: 134,g: 134,b: 134)
        }
        
        setTextView()
    }
    
    func setDidFinish(_ handler : @escaping ((UIImage, JSON, Date) -> Void)){
        self.didFinish = handler
    }
    
    func bind(){
        
        let expandView_tap = UITapGestureRecognizer()
        expandView.addGestureRecognizer(expandView_tap)
        let image_tap = UITapGestureRecognizer()
        photo_imageView.addGestureRecognizer(image_tap)
        
        close_btn.rx.tap
            .bind { (_) in
                if self.isType == .edit,
                   self.daily_textView.text != self.items.text ||
                   self.isImageEdit != false {
                        Alert.message("작성된 내용을  취소할까요?", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                            self.removeFromSuperview()
                        }))
                }else if self.isType == .write,
                         self.isImageEdit != false || self.daily_textView.text != "내용을 입력하세요"{
                    Alert.message("작성된 내용을  취소할까요?", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                        self.removeFromSuperview()
                    }))
                }else{
                    self.removeFromSuperview()
                }
        }.disposed(by: bag)
        
        photo_btn.rx.tap
            .bind { (_) in
                self.openPhoto()
        }.disposed(by: bag)

        edit_btn.rx.tap
            .bind { (_) in  //쓰기모로 전환
                self.date_view.isHidden = false
                self.edit_btn.isHidden = true
                self.delete_btn.isHidden = true
                self.isType = .edit
                self.bar_view.isHidden = false
                self.daily_textView.isEditable = true
                self.date_picker_view.isHidden = false
                self.date_picker_view.date = self.items.date
                self.instream_btn.setImage(UIImage(named: "btn_hd_write"), for: .normal)
                self.photo_btn.isHidden = false
                self.photo_btn.setImage(UIImage(named: ""), for: .normal)
                self.daily_textView.textColor = UIColor(r: 48,g: 48,b: 48)
        }.disposed(by: bag)
        
        
        delete_btn.rx.tap
            .bind { (_) in
                Alert.message("작성된 내용을 삭제할까요?", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                    self.realmDelete(self.items)
                }))
        }.disposed(by: bag)
        
        instream_btn.rx.tap
            .bind { (_) in
                if self.isType == .view {
                    Alert.message("인스타그램 스토리에\n 공유할까요?", leftAction: AlertAction(title: "아니요"), rightAction: AlertAction(title: "예", action: {
                        self.instreamGo()
                    }))
                }
                else{
                    if self.isType == .edit,        //편집모드
                       self.daily_textView.text == self.items.text,
                       self.isImageEdit == false,
                       self.items.date == self.date_picker_view.date{
                            self.removeFromSuperview()
                    }
                    else {          //쓰기모드
                        if self.daily_textView.text == "내용을 입력하세요" {
                            self.daily_textView.text = ""
                        }
                        let randXPoint = arc4random_uniform(3)
                        var data = JSON()
                        data["defaultImage"] = JSON(randXPoint)
                        
                        if self.photo_imageView.image != nil{      //사진등록할경우
                            self.photo_imageView.image = self.resizeImage(image: self.photo_imageView.image!, newWidth: 1024)
                            self.imageData = self.photo_imageView.image?.jpegData(compressionQuality: 0.1)
                            self.saveNewUser(data)      //데이터 저장
                        }
                        else {      //사진 등록을 안할경우 만들어준다
                            self.photo_imageView.image = UIImage(named: "img_dafault_0\(randXPoint)")
                            if self.photo_imageView.image != nil{
                                self.saveNewUser(data)      //데이터 저장
                            }
                        }
                        self.removeFromSuperview()
                    }
                }
        }.disposed(by: bag)
        
        
        expandView_tap.rx.event
            .bind{ event in
                self.daily_textView.endEditing(true)
            }.disposed(by: bag)
        
        image_tap.rx.event
            .bind{ event in
                App.module.presenter.addSubview(.visibleView, type: PhotoView.self){ view in
                    view.photos_imageView.image = self.photo_imageView.image
                }
            }.disposed(by: bag)
    }

    
    /*
     새로운 다이어리 등록
    */
    fileprivate func saveNewUser(_ data : JSON) {
        var id = 0
        
        if App.DayData.isEmpty {
            id = 0
        }
        else{
            if let num = App.DayData.max(by: {$0.id < $1.id}) {
                id = num.id + 1
            }
        }

        var jsonData = data
        jsonData["id"] = JSON(id)
        jsonData["text"] = JSON(daily_textView.text ?? "")
        //log.d(jsonData)
        
        if isType == .edit {
            realmUpdate(items)
            
            var editDate = false
            
            if items.date != date_picker_view.date {
                editDate = true
            }
            
            items.date = date_picker_view.date
            items.text = jsonData["text"].stringValue
            items.imageData = imageData
            
            mainView.editCell(items, editDate)
            removeFromSuperview()
        }
        else if isType == .write{
            realmSave(jsonData)
        }
        
        
        self.didFinish(photo_imageView.image!, data, date_picker_view.date)     //데이터 전달
    }
}

