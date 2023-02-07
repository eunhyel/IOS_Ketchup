//
//  ViewController.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/18.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import RealmSwift

class ViewController: UIViewController {

    @IBOutlet weak var year_label: UILabel!
    @IBOutlet weak var month_label: UILabel!
    
    @IBOutlet weak var write_btn: UIButton!
    @IBOutlet weak var setting_btn: UIButton!
    
    @IBOutlet weak var page_scrollview: UIScrollView!
    @IBOutlet weak var page_view: UIView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var defult_label: UILabel!
    
    @IBOutlet weak var pre_btn: UIButton!
    @IBOutlet weak var next_btn: UIButton!
    
    let bag = DisposeBag()
    var count = 1
    var pages : [BCItemPage] = []
    var selectedItem : DailyModel!
    
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
            setDataLoad()
            bind()
            setView()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //암호설정했으면 암호창 띄움
        if UserDefaults.standard.bool(forKey: "password")  {
            if App.isFirst == false {
                present("BlurPasswordLoginViewController")
                App.isFirst = true
            }
        }
        
        let isUpdata = isUpdateAvailable()
        
        if isUpdata {
            log.d("업데이트 필요")
            let alertController = UIAlertController.init(title: "필수 업데이트", message: "열심히 수정하였습니다. 업데이트 부탁드립니다ㅜ", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction.init(title: "업데이트", style: UIAlertAction.Style.default, handler: { (action) in
                    // 앱스토어마켓으로 이동
                UIApplication.shared.open(URL(string: "https://apps.apple.com/kr/app/%EC%BC%80%EC%B1%B1/id1558957782")!, options: [:], completionHandler: nil)
            }))
            self.present(alertController, animated: false, completion: {})
        }   
    }
    

    func setView(){
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: Global.backgroundImage)!)

        if App.DayData.isEmpty {
            year_label.text = String(Calendar.current.component(.year, from: Date()))
            month_label.text = String(Calendar.current.component(.month, from: Date())) + "월"
        }
        else {
            let maxDate = App.DayData.max(by: {$0.date < $1.date})
            
            year_label.text = String(Calendar.current.component(.year, from: maxDate!.date))
            month_label.text = String(Calendar.current.component(.month, from: maxDate!.date)) + "월"
        }
        
        next_btn.isEnabled = false
        next_btn.setImage(UIImage(named: "btn_page_next_disa"), for: .normal)
        
        if !App.DayData.isEmpty {
            defult_label.isHidden = true
        }

        createPages()
        setScrollView()
    }
    
    
    
    
    /*
     데이터 로드하고 리프래쉬
     */
    func setDataLoad() {
        if self.appDelegate.cloudStatus {
            getAllUsers()
        }
        else {
            realmLoad()
        }
         realmLoad()
    }
    
    

    
    /*
     데이터 갱신처리
     */
    func merge(_ date : Date){
        insertCell(date)
        page_scrollview.contentOffset.x = page_scrollview.frame.size.width *  CGFloat(count - 1)
    }

    
    /*
     디바이스 안에 있는 데이터 가져와서 저장
     */
    func getAllUsers() {
        let _: [Day] = CoreDataManager.shared.getDayModel(ascending: true, completion: { data in
            App.DayData = data.compactMap{ item -> DailyModel? in
                for _ in data{
                        var model = DailyModel()
                        model.id = Int(item.id)
                        model.text = item.text ?? ""
                        model.defaultImage = Int(item.defaultImage)
                        model.date = item.date ?? Date()
                        model.imageData = item.imageData
                        if !UserDefaults.standard.bool(forKey: "isDataSet") {
                            self.realmSave(model)
                        }
                        log.d(model)
                        return model
                    }
                UserDefaults.standard.set(true, forKey: "isDataSet")
                return nil
             }
        })
    
        //첫 시작이면 동기화 데이터 세팅
        if !UserDefaults.standard.bool(forKey: "isFirstStart")  {
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
               self.reloadAllViewControllers()
                UserDefaults.standard.set(true, forKey: "isFirstStart")
           }
        }
    }
    
    func realmLoad(){
        let realm = try! Realm()
        let savedDates = realm.objects(DataRealm.self)
        App.DayData = savedDates.compactMap{ item -> DailyModel? in
            for _ in savedDates{
                    var model = DailyModel()
                    model.id = item.id
                    model.text = item.text
                    model.defaultImage = Int(item.defaultImage)
                    model.date = item.date ?? Date()
                    model.imageData = item.imageData
                    log.d(model)
                    return model
                }
                return nil
         }
    }
    
    
    func realmSave(_ data : DailyModel){
        let dateSelected = DataRealm()
        dateSelected.id = data.id
        dateSelected.text = data.text
        dateSelected.date = data.date
        dateSelected.defaultImage = data.defaultImage
        dateSelected.page = 0
        dateSelected.imageData = data.imageData

        let realm = try! Realm()
        
        // Realm 에 저장하기
        try! realm.write {
            realm.add(dateSelected, update: .modified)
        }
    }
    
    
    
    
    
    func isUpdateAvailable() -> Bool {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,

            let url = URL(string: "https://itunes.apple.com/lookup?bundleId=1558957782"),

            let data = try? Data(contentsOf: url),

            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],

            let results = json["results"] as? [[String: Any]],

            results.count > 0,

            let appStoreVersion = results[0]["version"] as? String

            else { return false }

        if !(version == appStoreVersion) { return true }

        else{ return false }

    }
}

