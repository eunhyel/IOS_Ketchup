//
//  Day+CoreDataProperties.swift
//  
//
//  Created by eunhye on 2021/02/25.
//
//

import Foundation
import CoreData


extension Day {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Day> {
        return NSFetchRequest<Day>(entityName: "Day")
    }

    @NSManaged public var id: Int64
    @NSManaged public var defaultImage: Int64
    @NSManaged public var date: Date?
    @NSManaged public var text: String?
    @NSManaged public var page: Int64
    @NSManaged public var imageData: Data?
}
