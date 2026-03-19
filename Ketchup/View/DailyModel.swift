//
//  DailyModel.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/22.
//

import Foundation
import RxSwift
import CoreData
import SwiftyJSON

struct DailyModel {
    var id : Int = 0
    var defaultImage : Int = 1
    var date : Date = Date()
    var text : String = ""
    var imageData : Data? = nil
}


class TextModel {
    let newMessage = BehaviorSubject<String>(value: "")
    var observedMessage:Observable<String> {
        return newMessage.asObservable()
    }
}
