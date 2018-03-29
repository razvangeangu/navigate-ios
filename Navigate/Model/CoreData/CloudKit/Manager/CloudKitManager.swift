//
//  CloudKitManager.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 28/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//  https://tongtian.wordpress.com/2017/03/04/sync-core-data-with-cloudkit-part-2/

import Foundation
import CoreData
import CloudKit

class CloudKitManager {
    static let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    static var cacheContext = PersistenceService.cacheContext
    static var updateContext = PersistenceService.updateContext
    
    /**
     
     
     - parameter savedIDs:
     - parameter deletedIDs:
     */
    static func uploadChangedObjects(savedIDs: [NSManagedObjectID], deletedIDs: [CKRecordID]?) {
        
        let task = beginBackgroundTask()
        
        // Create var for the saved objects as cloud managed objects
        var savedObjects = [CKRecord]()
        
        // Get all the objects to save cloud managed objects
        for savedID in savedIDs {
            let savedObject = PersistenceService.viewContext.object(with: savedID) as! CloudKitManagedObject
            let record = savedObject.managedObjectToRecord()
            savedObjects.append(record)
        }
        
        // Split into maximum number of chunks allowed by CloudKit
        let recordsChunks = savedObjects.chunks(400)
        
        for chunkID in 0..<recordsChunks.count {
            DispatchQueue.main.async {
                // Create a new modify records operation
                let operation = CKModifyRecordsOperation(recordsToSave: recordsChunks[chunkID], recordIDsToDelete: chunkID == 0 ? deletedIDs : nil)
                
                operation.name = "\(chunkID + 1)"
                
                // Set completion block per record
                operation.perRecordCompletionBlock = { record, error in
                    // If there is an error
                    if let error = error as? CKError {
                        
                        // If there is a server record stored
                        if let serverRecord = error.serverRecord, let clientRecord = error.clientRecord {
                            
                            // If the error code represents the server record different last update time
                            if error.code == .serverRecordChanged {
                                
                                // Get the last update time for the client record
                                if let clientLastUpdate = clientRecord["lastUpdate"] as? Date {
                                    
                                    // Get the last update time for the server record
                                    if let serverLastUpdate = serverRecord["lastUpdate"] as? Date {
                                        
                                        // If the server last update time is earlier than the clients' one
                                        if serverLastUpdate.compare(clientLastUpdate) == .orderedAscending {
                                            // Add to cache context for later update
                                            let cachedRecord = CachedRecords(context: cacheContext)
                                            cachedRecord.recordName = clientRecord.recordID.recordName
                                            cachedRecord.modificationDate = NSDate()
                                            
                                            // Save the cache context
                                            PersistenceService.saveCacheContext()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Set the completion handler for the operation
                operation.modifyRecordsCompletionBlock = { records, recordsID, error in
                    
                    // If there is an error
                    if let error = error as? CKError {
                        
                        if error.code == .limitExceeded {
                            MapViewController.devLog(data: "Modify limit exceeded")
                            
                            // If app had partial failure, update the cached records to overwrite the changes
                        } else if error.code == .partialFailure {
                            do {
                                
                                // get the cached records from the cached context
                                let cachedRecords = try cacheContext.fetch(NSFetchRequest(entityName: "CachedRecords"))
                                
                                // If there are cached records to be modified
                                if let cachedRecords = cachedRecords as? [CachedRecords], cachedRecords.count > 0 {
                                    
                                    // Get the record names
                                    let recordNames = cachedRecords.map({ $0.recordName! })
                                    
                                    // Get the unique names (remove duplicates for multiple changes)
                                    let uniqueNames = Array(Set(recordNames))
                                    
                                    // Create vars to save records from block
                                    var recordsToSave: [CKRecord] = []
                                    var recordIDsToDelete: [CKRecordID] = []
                                    
                                    for recordName in uniqueNames {
                                        // Get the managed object for the unique name
                                        let managedObject = object(in: PersistenceService.viewContext, recordName: recordName)
                                        
                                        // Cast to cloud managed object
                                        if let cloudManagedObject = managedObject as? CloudKitManagedObject {
                                            
                                            // Get the record and add it to the var
                                            let record = cloudManagedObject.managedObjectToRecord()
                                            recordsToSave.append(record)
                                        } else {
                                            
                                            // If the record is existent anymore, we want to delete it from the cloud
                                            let recordID = CKRecordID(recordName: recordName, zoneID: CKRecordZone.default().zoneID)
                                            recordIDsToDelete.append(recordID)
                                        }
                                    }
                                    
                                    // Clear the cached records from the context
                                    clearCachedRecords(recordNames: recordNames, completion: { (_) in
                                        
                                        // Update iCloud database
                                        uploadCachedRecords(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
                                    })
                                }
                            } catch {
                                MapViewController.devLog(data: "Error in fetchRequest for CachedRecords.")
                            }
                        } else if error.code == .invalidArguments {
                            MapViewController.devLog(data: "Invalid arguments provided for \(String(describing: records))")
                        } else {
                            MapViewController.devLog(data: error.localizedDescription)
                        }
                    }
                }
                
                operation.completionBlock = {
                    MapViewController.devLog(data: "Finished uploading changed objects to the cloud. (\(operation.name ?? "")/\(recordsChunks.count))")
                    if operation.name == String(recordsChunks.count) {
                        endBackgroundTask(taskID: task)
                    }
                }
                
                operation.qualityOfService = .userInitiated
                
                // Add operation to the public database
                publicCloudDatabase.add(operation)
            }
        }
    }
    
    static func uploadCachedRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecordID]) {
        let recordsChunks = recordsToSave.chunks(400)
        for records in recordsChunks {
            DispatchQueue.main.async {
                let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordsChunks.index(of: records) == recordsChunks.startIndex ? recordIDsToDelete : nil)
                operation.name = "\(String(describing: recordsChunks.index(of: records)?.advanced(by: 1)))"
                operation.savePolicy = .allKeys
                
                operation.perRecordCompletionBlock = { record, error in
                    if let error = error as? CKError {
                        MapViewController.devLog(data: error.localizedDescription)
                    }
                }
                
                operation.modifyRecordsCompletionBlock = { record, recordID, error in
                    if let error = error as? CKError {
                        if error.code == CKError.limitExceeded {
                            MapViewController.devLog(data: "Modify limit exceeded.")
                        } else {
                            MapViewController.devLog(data: error.localizedDescription)
                        }
                    }
                }
                
                operation.completionBlock = {
                    MapViewController.devLog(data: "Finished uploading cached records to the cloud. (\(operation.name ?? "")/\(recordsChunks.count))")
                }
                
                operation.qualityOfService = .userInitiated
                
                publicCloudDatabase.add(operation)
            }
        }
    }
    
    static func clearCachedRecords(recordNames: [String], completion: (([NSManagedObjectID]) -> Void)?) {
        cacheContext.perform {
            for recordName in recordNames {
                if let objects = objects(entityName: "CachedRecords", in: cacheContext, withRecordName: recordName) {
                    for object in objects {
                        cacheContext.delete(object as! NSManagedObject)
                    }
                }
            }
            
            PersistenceService.saveCacheContext()
            
            let cachedRecords = objects(entityName: "CachedRecords", in: cacheContext)
            if let objects = cachedRecords, objects.count > 0 {
                completion?(objects.map({ $0.objectID }))
            }
        }
    }
    
    static func updateLocalRecord(from recordID: CKRecordID, reason: CKQueryNotificationReason) {
        if reason == .recordCreated || reason == .recordUpdated {
            publicCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
                if let _ = error {
                    MapViewController.devLog(data: "Error while fetching in updateLocalRecord.")
                } else {
                    if let record = record {
                        updateContext.perform {
                            updateObject(for: [record])
                            
                            PersistenceService.saveUpdateContext()
                            
                            if let dotIndex = recordID.recordName.index(of: ".") {
                                let recordType = String(recordID.recordName[...recordID.recordName.index(before: dotIndex)])
                                MapViewController.reloadView(recordType: recordType)
                            }
                        }
                    }
                }
            }
        } else if reason == .recordDeleted {
            updateContext.perform {
                deleteObject(recordNames: [recordID.recordName])
                
                PersistenceService.saveUpdateContext()
                
                if let dotIndex = recordID.recordName.index(of: ".") {
                    let recordType = String(recordID.recordName[...recordID.recordName.index(before: dotIndex)])
                    MapViewController.reloadView(recordType: recordType)
                }
            }
        }
    }
    
    static func updateLocalRecords(changedRecords: [CKRecord], deletedRecordIDs: [CKRecordID]?) {
        updateContext.perform {
            updateObject(for: changedRecords)
            
            if let deletedRecordIDs = deletedRecordIDs, deletedRecordIDs.count > 0 {
                let deletedRecordNames = deletedRecordIDs.map { $0.recordName }
                deleteObject(recordNames: deletedRecordNames)
            }
            
            PersistenceService.saveUpdateContext()
        }
    }
    
    static func fetchDataFromTheCloud(completion: (() -> Void)?) {
        
        MapViewController.progressView.setProgress(to: 0)
        DispatchQueue.global(qos: .userInteractive).async {
            query(recordType: DataClasses.floor.rawValue) { (_) in
                query(recordType: DataClasses.room.rawValue) { (_) in
                    query(recordType: DataClasses.tile.rawValue) { (completed) in
                        query(recordType: DataClasses.accessPoint.rawValue) { (completed) in
                            completion?()
                        }
                    }
                }
            }
        }
    }
}
