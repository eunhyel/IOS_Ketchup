//
//
//  Copyright © 2020 Inforex. All rights reserved.
//

import Foundation
import SwiftyJSON
import RxSwift
import RxCocoa
import Kingfisher

class FontView: XibView, UITableViewDataSource, UITableViewDelegate{

    
    @IBOutlet weak var close_btn: UIButton!
    @IBOutlet weak var setting_tableview: UITableView!
    @IBOutlet weak var font_view: UIView!
    
    let menu : [String] = ["숑숑체",
                           "손글씨체",
                           "서라운드체",
                           "아네모네에어체",
                           "나눔스퀘어체",
                           "리디바탕체"]
    
    fileprivate var items: [String]!
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    let bag = DisposeBag()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if isInitailized {
            isInitailized = false
            initialize()
        }
    }

    func initialize(){
        items = [appDelegate.Cafe24Syongsyong.familyName,
                 appDelegate.KyoboHandwriting2019.familyName,
                 appDelegate.Cafe24SSurround.familyName,
                 appDelegate.Cafe24Ohsquareair.familyName,
                 appDelegate.NanumSquareOTFL.familyName,
                 appDelegate.RidiBatang.familyName]
        
        setShadow()
        setView()
        bind()
    }
    
    func setShadow(){
        font_view.layer.shadowColor = UIColor(r: 0, g: 0, b: 0, a: 0.2).cgColor
        font_view.layer.shadowOpacity = 1
        font_view.layer.shadowOffset = CGSize(width: 0, height: 0)
        font_view.layer.shadowRadius = 4
        let bounds = font_view.bounds
        let shadowPath = UIBezierPath(rect: CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: bounds.height)).cgPath
        font_view.layer.shadowPath = shadowPath
        font_view.layer.shouldRasterize = true
        font_view.layer.rasterizationScale = UIScreen.main.scale
    }
    
    func setView(){
        self.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)
        setTableView()
    }
    
    func bind(){
        close_btn.rx.tap
            .bind { (_) in
                self.removeFromSuperview()
        }.disposed(by: bag)
    }
    
    func close(){

    }
    
    func reloadAllViewControllers() {
        let storyboard = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.storyboard
        let id = UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController?.value(forKey: "storyboardIdentifier")
        let rootVC = storyboard?.instantiateViewController(withIdentifier: id as! String)
        UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.rootViewController = rootVC
        App.module.presenter.addSubview(.visibleView, type: FontView.self){ view in
        }
    }
    
    func setTableView() {
        setting_tableview.register(UINib(nibName: "MenuCell", bundle: nil), forCellReuseIdentifier: "MenuCell")
        setting_tableview.dataSource = self
        setting_tableview.delegate = self
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath) as? MenuCell else{
            return UITableViewCell()
        }
        
        let text : String = indexPath.section == 0 ? self.menu[indexPath.row] : ""
        
        cell.name_label.font = UIFont(name: self.items[indexPath.row], size: UIFont.labelFontSize)
        
        if FontManager.shared.currentFont?.familyName ==  self.items[indexPath.row]{
            cell.name_label.textColor = UIColor(r: 237, g: 81, b: 81)
        }
        
        cell.name_label.text = text
        
        let tap = UITapGestureRecognizer()
        cell.addGestureRecognizer(tap)
        
        tap.rx.event
            .bind{ _ in
                FontManager.shared.reset()
                UserDefaults.standard.set(self.items[indexPath.row], forKey: persistFontKey)
                switch self.items[indexPath.row] {
                    case self.appDelegate.Cafe24Syongsyong.familyName:
                        FontManager.shared.currentFont = self.appDelegate.Cafe24Syongsyong
                        break
                    case self.appDelegate.RidiBatang.familyName:
                        FontManager.shared.currentFont = self.appDelegate.RidiBatang
                        break
                    case self.appDelegate.NanumSquareOTFL.familyName:
                        FontManager.shared.currentFont = self.appDelegate.NanumSquareOTFL
                        break
                    case self.appDelegate.KyoboHandwriting2019.familyName:
                        FontManager.shared.currentFont = self.appDelegate.KyoboHandwriting2019
                        break
                    case self.appDelegate.Cafe24SSurround.familyName:
                        FontManager.shared.currentFont = self.appDelegate.Cafe24SSurround
                        break
                    case self.appDelegate.Cafe24Ohsquareair.familyName:
                        FontManager.shared.currentFont = self.appDelegate.Cafe24Ohsquareair
                        break
                    default:
                        break
                    }
                self.reloadAllViewControllers()
            }
            .disposed(by: bag)
        
        return cell
    }
}

