//
//  PersistenceServiceCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 26/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
// https://tongtian.wordpress.com/2017/03/04/sync-core-data-with-cloudkit-part-2/

import CoreData
import CloudKit

extension PersistenceService {
    
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
    
    static func deleteObject(for recordNames: [String]) {
        for recordName in recordNames {
            if let object = object(in: updateContext, recordName: recordName) {
                RGSharedDataManager.updateContext.delete(object)
            }
        }
    }
    
    static func updateObject(for records: [CKRecord]) {
        for record in records {
            let recordName = record.recordID.recordName

            if let managedObject = object(in: RGSharedDataManager.updateContext, recordName: recordName) as? CloudKitManagedObject {
                if let lastUpdate = record["lastUpdate"] as? Date {
                    if lastUpdate.compare(managedObject.lastUpdate! as Date) == .orderedDescending {
                        managedObject.update(with: record)
                    }
                }
            } else {
                if let dotIndex = recordName.index(of: ".") {
                    let entityName = String(recordName[...recordName.index(before: dotIndex)])
                    let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: RGSharedDataManager.updateContext)
                    if let cloudManagedObject = newObject as? CloudKitManagedObject {
                        cloudManagedObject.update(with: record)
                    }
                }
            }
        }
    }
    
    static func updateLocalRecords(changedRecords: [CKRecord], deletedRecordIDs: [CKRecordID]?) {
        RGSharedDataManager.updateContext.perform {
            self.updateObject(for: changedRecords)
            
            if let deletedRecordIDs = deletedRecordIDs, deletedRecordIDs.count > 0 {
                let deletedRecordNames = deletedRecordIDs.map { $0.recordName }
                self.deleteObject(for: deletedRecordNames)
            }
            
            if RGSharedDataManager.updateContext.hasChanges {
                do {
                    try RGSharedDataManager.updateContext.save()
                } catch {
                    debugPrint("Error in saving updateContext while updating local records.")
                }
            }
        }
    }
    
    static func clearCachedRecords(recordNames: [String], completion: (([NSManagedObjectID]) -> Void)?) {
        RGSharedDataManager.cachedContext.perform {
            for recordName in recordNames {
                if let objects = objects(entityName: "CachedRecords", in: RGSharedDataManager.cachedContext, withRecordName: recordName) {
                    for object in objects {
                        RGSharedDataManager.cachedContext.delete(object as! NSManagedObject)
                    }
                }
            }
            
            if RGSharedDataManager.cachedContext.hasChanges {
                do {
                    try RGSharedDataManager.cachedContext.save()
                } catch {
                    debugPrint("Error saving cached context while trying to clear cached records.")
                }
            }
            
            let cachedRecords = objects(entityName: "CachedRecords", in: RGSharedDataManager.cachedContext)
            if let objects = cachedRecords, objects.count > 0 {
                completion?(objects.map({ $0.objectID }))
            }
        }
    }
}

