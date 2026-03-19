//
//  CoreDataManager.swift
//  dailyApp
//
//  Created by eunhye on 2021/02/25.
//

import Foundation
import CoreData
import UIKit

class  CoreDataManager {
    static let shared: CoreDataManager = CoreDataManager()
    
    let modelName: String = "Day"
    
    static var persistenContainer:  NSPersistentContainer  = {
        let container = NSPersistentCloudKitContainer(name: "DayModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
            }
        })
        return container
    }()
    
    func getDayModel(ascending: Bool = false, completion: (([Day]) -> Void)? = nil) -> [Day]{
        var models: [Day] = [Day]()
        
        let idSort: NSSortDescriptor = NSSortDescriptor(key: "id", ascending: ascending)
        let fetchRequest: NSFetchRequest<NSManagedObject>
            = NSFetchRequest<NSManagedObject>(entityName: modelName)
        fetchRequest.sortDescriptors = [idSort]
        
        do {
            if let fetchResult: [Day] = try CoreDataManager.persistenContainer.viewContext.fetch(fetchRequest) as? [Day] {
                models = fetchResult
            }
        } catch let error as NSError {
            print("Could not fetch: \(error), \(error.userInfo)")
        }
        
        if let completion = completion {
            completion(models)
        }
        return models
    }
    
    func saveDay(id: Int64, text: String, defaultImage: Int64 = 1, date : Date, page: Int64, imageData: Data? = nil, onSuccess: @escaping ((Bool) -> Void)) {
        if let entity: NSEntityDescription
            = NSEntityDescription.entity(forEntityName: modelName, in: CoreDataManager.persistenContainer.viewContext) {
            
            if let user: Day = NSManagedObject(entity: entity, insertInto: CoreDataManager.persistenContainer.viewContext) as? Day {
                user.id = id
                user.text = text
                user.defaultImage = defaultImage
                user.date = date
                user.page = page
                user.imageData = imageData
                
                contextSave { success in
                    onSuccess(success)
                }
            }
        }
    }
    
    
    func deleteUser(id: Int64, onSuccess: @escaping ((Bool) -> Void)) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = filteredRequest(id: id)
        
        do {
            if let results: [Day] = try CoreDataManager.persistenContainer.viewContext.fetch(fetchRequest) as? [Day] {
                if results.count != 0 {
                    CoreDataManager.persistenContainer.viewContext.delete(results[0])
                }
            }
        } catch let error as NSError {
            print("Could not fatch🥺: \(error), \(error.userInfo)")
            onSuccess(false)
        }
        
        contextSave { success in
            onSuccess(success)
        }
    }
}



extension CoreDataManager {
    fileprivate func filteredRequest(id: Int64) -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult>
            = NSFetchRequest<NSFetchRequestResult>(entityName: modelName)
        fetchRequest.predicate = NSPredicate(format: "id = %@", NSNumber(value: id))
        return fetchRequest
    }
    
    fileprivate func contextSave(onSuccess: ((Bool) -> Void)) {
        do {
            try CoreDataManager.persistenContainer.viewContext.save()
            onSuccess(true)
        } catch let error as NSError {
            print("Could not save🥶: \(error), \(error.userInfo)")
            onSuccess(false)
        }
    }
}
