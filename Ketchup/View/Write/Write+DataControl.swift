//
//  Write+DataContol.swift
//  Ketchup
//
//  Created by eunhye on 2021/04/09.
//

import Foundation
import SwiftyJSON

extension WriteView {
    
    
    /*
     쓰기 저장
     */
    func realmSave(_ data : JSON){
        //Icloud 동기화면 거기다가도 저장
        if UserDefaults.standard.bool(forKey: "useICloud") {
            saveUser(data,imageData,date_picker_view.date)
        }
        log.d(date_picker_view.date)
        let dateSelected = DataRealm()
        dateSelected.id = data["id"].intValue
        dateSelected.text = data["text"].stringValue
        dateSelected.date = date_picker_view.date
        dateSelected.defaultImage = data["defaultImage"].intValue
        dateSelected.page = 0
        dateSelected.imageData = imageData

        // Realm 에 저장하기
        try! realm.write {
            App.DayData.append(DailyModel(id: data["id"].intValue, defaultImage: data["defaultImage"].intValue, date: date_picker_view.date, text: data["text"].stringValue, imageData: imageData))
            realm.add(dateSelected, update: .modified)
        }
    }
    
    
    
    
    /*
     삭제하기
     */
    
    func realmDelete(_ data : DailyModel){
        //Icloud 동기화면 거기다가도 저장
        if UserDefaults.standard.bool(forKey: "useICloud") {
            self.deleteUser()
        }
        
        let dateSelected = DataRealm()
        dateSelected.id = data.id
        dateSelected.text = data.text
        dateSelected.date = data.date
        dateSelected.defaultImage = data.defaultImage
        dateSelected.page = 0
        dateSelected.imageData = data.imageData

        if  let userinfo = realm.objects(DataRealm.self).filter(NSPredicate(format: "id = %@", NSNumber(value: data.id))).first {
              try! realm.write {
                realm.delete(userinfo)
              }
          }else{
              print("없는데요??")
          }
        
        mainView.deleteCell(data)
        
        if self.isType == .view {
            self.removeFromSuperview()
        }
    }
    
    
    
    
    /*
     수정하기
     */
    func realmUpdate(_ data : DailyModel){
        if UserDefaults.standard.bool(forKey: "useICloud") {
            deleteUser()
            CoreDataManager.shared
                .saveDay(id: Int64(data.id),
                         text: daily_textView.text,
                         defaultImage: Int64(data.defaultImage),
                         date: date_picker_view.date,
                         page: 0,
                         imageData: imageData) {onSuccess in
                    
                    log.d("saved = \(onSuccess)")
            }
        }
        
        if  let userinfo = realm.objects(DataRealm.self).filter(NSPredicate(format: "id = %@", NSNumber(value: data.id))).first {
           try! realm.write {
            userinfo.text = daily_textView.text
            userinfo.imageData = imageData
            userinfo.date = date_picker_view.date
           }
       }else{
            log.d("수정실패")
       }
    }
    
    
    
    
    
    
    
    
    
    
    
    /* ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ ICloud Data Control ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ */
    
    /*
     데이저 저장
     */
    func saveUser(_ jsonData : JSON, _ imageData : Data? = nil, _ date : Date) {
        CoreDataManager.shared
            .saveDay(id: jsonData["id"].int64Value,
                     text: jsonData["text"].stringValue,
                     defaultImage: jsonData["defaultImage"].int64Value,
                     date: date,
                     page: jsonData["page"].int64Value,
                     imageData: imageData) {onSuccess in
                
                log.d("saved = \(onSuccess)")
        }
    }
    
    /*
     데이터 삭제
     */
    func deleteUser() {
        CoreDataManager.shared.deleteUser(id: Int64(self.items.id)) { onSuccess in
            log.d("deleted = \(onSuccess)")
        }
    }
}
