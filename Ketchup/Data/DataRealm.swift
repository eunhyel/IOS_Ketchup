//
//  DataRealm.swift
//  Ketchup
//
//  Created by eunhye on 2021/05/12.
//

import Foundation
import RealmSwift

class DataRealm: Object{
    @objc dynamic var id = 0
    @objc dynamic var defaultImage = 0
    @objc dynamic var date: Date? = nil
    @objc dynamic var text = ""
    @objc dynamic var page = 0
    @objc dynamic var imageData: Data? = Data()
    override class func primaryKey() -> String? {
        return "id"
      }
}
