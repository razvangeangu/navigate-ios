//
//  CloudKitManagerObjectsExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 28/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

extension CloudKitManager {
    static func object(in context: NSManagedObjectContext, recordName: String) -> NSManagedObject? {
        if let dotIndex = recordName.index(of: ".") {
            let entityName = String(recordName[...recordName.index(before: dotIndex)])
            
            do {
                let entities = try context.fetch(NSFetchRequest(entityName: entityName))
                for case let entity as CloudKitManagedObject in entities {
                    if entity.recordName == recordName {
                        return entity as? NSManagedObject
                    }
                }
            } catch {
                debugPrint("Error in Floor fetchRequest")
            }
        }
        
        return nil
    }
    
    static func objects(entityName: String, in context: NSManagedObjectContext, withRecordName name: String) -> [CloudKitManagedObject]? {
        var entitiesToReturn = [CloudKitManagedObject]()
        
        do {
            let entities = try context.fetch(NSFetchRequest(entityName: entityName))
            for case let entity as CloudKitManagedObject in entities {
                if entity.recordName == name {
                    entitiesToReturn.append(entity)
                }
            }
            
            if !entitiesToReturn.isEmpty {
                return entitiesToReturn
            }
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    static func objects(entityName: String, in context: NSManagedObjectContext) -> [NSManagedObject]? {
        var entitiesToReturn = [NSManagedObject]()
        
        do {
            let entities = try context.fetch(NSFetchRequest(entityName: entityName))
            for case let entity as NSManagedObject in entities {
                entitiesToReturn.append(entity)
            }
            
            if !entitiesToReturn.isEmpty {
                return entitiesToReturn
            }
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    static func updateObject(for records: [CKRecord]) {
        for record in records {
            let recordName = record.recordID.recordName
            
            if let managedObject = object(in: updateContext, recordName: recordName) as? CloudKitManagedObject {
                if let lastUpdate = record["lastUpdate"] as? Date {
                    if lastUpdate.compare(managedObject.lastUpdate! as Date) == .orderedDescending {
                        managedObject.update(with: record)
                    }
                }
            } else {
                if let dotIndex = recordName.index(of: ".") {
                    let entityName = String(recordName[...recordName.index(before: dotIndex)])
                    let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: updateContext)
                    if let cloudManagedObject = newObject as? CloudKitManagedObject {
                        cloudManagedObject.update(with: record)
                    }
                }
            }
        }
    }
    
    static func deleteObject(recordNames: [String]) {
        for recordName in recordNames {
            if let object = object(in: updateContext, recordName: recordName) {
                updateContext.delete(object)
            }
        }
    }
}
