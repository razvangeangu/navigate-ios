//
//  PersistenceServiceCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 26/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData
import CloudKit

extension PersistenceService {
    
    static func object(from entityName: String, in context: NSManagedObjectContext, withRecordName name: String) -> NSManagedObject? {
        do {
            let entities = try context.fetch(NSFetchRequest(entityName: entityName))
            for case let entity as CloudKitManagedObject in entities {
                if entity.recordName == name {
                    return entity as? NSManagedObject
                }
            }
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    static func objects(from entityName: String, in context: NSManagedObjectContext, withRecordName name: String) -> [NSManagedObject?]? {
        var entitiesToReturn = [NSManagedObject]()
        
        do {
            let entities = try context.fetch(NSFetchRequest(entityName: entityName))
            for case let entity as CloudKitManagedObject in entities {
                if entity.recordName == name {
                    entitiesToReturn.append((entity as? NSManagedObject)!)
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
    
    static func objects(for entityName: String, context: NSManagedObjectContext) -> [NSManagedObject]? {
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
    
    static func updateLocalRecords(changedRecords: [CKRecord], deletedRecordIDs: [CKRecordID]) {
        updateContext.perform {
            let deletedRecordNames = deletedRecordIDs.map { $0.recordName }
            self.updateObject(for: changedRecords)
            self.deleteObject(for: deletedRecordNames)
            self.saveUpdateContext()
        }
    }
    
    static func deleteObject(for recordNames: [String]) {
        for recordName in recordNames {
            if let object = retrieveObject(fromRecordName: recordName, context: updateContext) {
                updateContext.delete(object)
            }
        }
    }
    
    static func updateObject(for records: [CKRecord]) {
        for record in records {
            let recordName = record.recordID.recordName
            if let managedObject = retrieveObject(fromRecordName: recordName, context: viewContext) as? CloudKitManagedObject {
                if let lastUpdate = record["lastUpdate"] as? NSDate {
                    if managedObject.lastUpdate != lastUpdate {
                        managedObject.update(with: record)
                    }
                }
            } else {
                if let dotIndex = recordName.index(of: ".") {
                    let entityName = String(recordName[...dotIndex])
                    let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: updateContext)
                    if let cloudManagedObject = newObject as? CloudKitManagedObject {
                        cloudManagedObject.update(with: record)
                    }
                }
            }
        }
    }
    
    static func retrieveObject(fromRecordName: String, context: NSManagedObjectContext) -> NSManagedObject? {
        guard let dotIndex = fromRecordName.index(of: ".") else { return nil }
        let entityName = String(fromRecordName[...dotIndex])
        return object(from: entityName, in: context, withRecordName: fromRecordName)
    }
    
    static func persistUploadFailedRecords(recordNames: [String]) {
        cacheContext.perform {
            for name in recordNames {
                let record = CachedRecords(context: cacheContext)
                record.recordName = name
                record.modificationDate = NSDate()
            }
            saveCacheContext()
        }
    }
    
    static func clearCachedRecords(recordNames: [String]) {
        cacheContext.perform {
            for recordName in recordNames {
                if let objects = objects(from: "CachedRecords", in: cacheContext, withRecordName: recordName) {
                    for object in objects {
                        cacheContext.delete(object!)
                    }
                }
            }
            
            saveCacheContext()
            
            let cachedRecords = objects(for: "CachedRecords", context: cacheContext)
            if let objects = cachedRecords, objects.count > 0 {
                RGSharedDataManager.uploadCachedRecords(objects: cachedRecords!)
            }
        }
    }
}

