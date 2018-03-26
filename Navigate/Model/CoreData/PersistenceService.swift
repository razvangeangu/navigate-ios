//
//  PersistenceService.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 02/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import CoreData

class PersistenceService {
    private init() { }
    
    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    static var cacheContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    static var updateContext: NSManagedObjectContext {
        let _updateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        _updateContext.parent = self.viewContext
        return _updateContext
    }
    
    // MARK: - Core Data stack
    
    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "navigate-data")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                MapViewController.devLog(data: "Error with the persistent container")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    static func saveViewContext() {
        if viewContext.hasChanges {
            let insertedObjects = viewContext.insertedObjects
            let modifiedObjects = viewContext.updatedObjects
            let deletedRecordIDs = viewContext.deletedObjects.map { ($0 as! CloudKitManagedObject).cloudKitRecordID() }
            
            do {
                try viewContext.save()
            } catch {
                MapViewController.devLog(data: "Could not save context to CoreData")
            }
            
            let insertedObjectIDs = insertedObjects.map { $0.objectID }
            let modifiedObjectIDs = modifiedObjects.map { $0.objectID }
            RGSharedDataManager.uploadChangedObjects(savedIDs: insertedObjectIDs + modifiedObjectIDs, deletedIDs: deletedRecordIDs)
        }
    }
    
    static func saveUpdateContext() {
        if updateContext.hasChanges {
            do {
                try updateContext.save()
            } catch {
                MapViewController.devLog(data: "Could not save update context.")
            }
        }
    }
    
    static func saveCacheContext() {
        if cacheContext.hasChanges {
            do {
                try cacheContext.save()
            } catch {
                MapViewController.devLog(data: "Could not save cache context.")
            }
        }
    }
}
