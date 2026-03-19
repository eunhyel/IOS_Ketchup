//
//
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift
import RxCocoa
import Kingfisher

class SettingView: XibView, UITableViewDataSource, UITableViewDelegate{

    
    @IBOutlet weak var anotherView: UIView!
    @IBOutlet weak var tableview_back_view: UIView!
    @IBOutlet weak var setting_tableview: UITableView!
    
    var swipeLight : UISwipeGestureRecognizer!
    
    weak var mainView : ViewController!
    
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let menu : [String] = ["암호 설정","백업 및 동기화","글씨체 변경","개발자 한마디","케찹의 역사", "현재 버전"]     //,"배경이미지 설정"
    
    let bag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            initialize()
            isInitailized = false
        }
    }
    
    func initialize(){
        setView()
        bind()
    }
    
    func setView(){
        swipeRight.isEnabled = false
        tableview_back_view.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)
        setTableView()
        swipeLightRecognizer()
    }
    
    func bind(){
        let anotherTap = UITapGestureRecognizer()
        anotherView.addGestureRecognizer(anotherTap)
        
        anotherTap.rx.event
            .bind { (_) in
                self.anotherView.backgroundColor = .clear
                UIView.animate(withDuration: Global.removAniTime, animations: {
                    self.frame.origin.x = -UIScreen.main.bounds.width
                }, completion: { _ in
                    self.removeFromSuperview()
                })
            }.disposed(by: bag)
    }
    

    func swipeLightRecognizer() {
        swipeLight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToLightSwipeGesture(_:)))
        swipeLight.direction = UISwipeGestureRecognizer.Direction.left
        self.addGestureRecognizer(swipeLight)
    }
        
    @objc func respondToLightSwipeGesture(_ gesture: UIGestureRecognizer){
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction{
            case UISwipeGestureRecognizer.Direction.left:
                self.anotherView.backgroundColor = .clear
                UIView.animate(withDuration: Global.removAniTime, animations: {
                    self.frame.origin.x = -UIScreen.main.bounds.width
                }, completion: { _ in
                    self.removeFromSuperview()
                })
                break
            default: break
            }
        }
    }
    
    func setTableView() {
        setting_tableview.register(UINib(nibName: "MenuCell", bundle: nil), forCellReuseIdentifier: "MenuCell")
        setting_tableview.dataSource = self
        setting_tableview.delegate = self
        setting_tableview.estimatedRowHeight = 60
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as? MenuCell else{
            return UITableViewCell()
        }
        
        var text : String = indexPath.section == 0 ? self.menu[indexPath.row] : ""
        
        if text == "현재 버전" {
            text += "  \(currentVersion!)"
        }
        cell.name_label.text = text
        
        
        let tap = UITapGestureRecognizer()
        cell.addGestureRecognizer(tap)
        
        tap.rx.event
            .bind{ _ in
                switch indexPath.row {
                case 0:  //암호설정
                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "BlurPasswordLoginViewController") as! BlurPasswordLoginViewController
                    loginVC.modalPresentationStyle = .overCurrentContext
                    loginVC.isEdit = true
                    getNavigationController().present(loginVC, animated: true, completion: nil)
                case 1:  //데이터 백업
                    App.module.presenter.addSubview(.visibleView, type: BackUpView.self){ view in
                        view.mainView = self.mainView
                    }
                case 2:  //글씨체
                    App.module.presenter.addSubview(.visibleView, type: FontView.self){ view in
                    }
                case 3:  //한마디
                    App.module.presenter.addSubview(.visibleView, type: OneTalkView.self){ view in
                    }
                case 4:  //한마디
                    UIApplication.shared.open(URL(string: "https://www.instagram.com/ketchup.photo/")!, options: [:], completionHandler: nil)
                default:
                    print("없는 메뉴")
                }
            }
            .disposed(by: bag)
        
        return cell
    }
}

