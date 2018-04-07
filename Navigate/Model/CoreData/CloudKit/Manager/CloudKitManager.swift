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
     A function that updates the changed objects in the cloud.
     This application runs in background.
     
     - parameter savedIDs: The IDs of the managedObjects to be updated.
     - parameter deletedIDs: The IDs of the managedObjects to be deleted.
     */
    static func uploadChangedObjects(savedIDs: [NSManagedObjectID], deletedIDs: [CKRecordID]?) {
        
        // Start the background task
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
                
                // Completion block for the UI.
                operation.completionBlock = {
                    MapViewController.devLog(data: "Finished uploading changed objects to the cloud. (\(operation.name ?? "")/\(recordsChunks.count))")
                    if operation.name == String(recordsChunks.count) {
                        
                        // End the background task when uploading finished
                        endBackgroundTask(taskID: task)
                    }
                }
                
                // Set the quality of service
                operation.qualityOfService = .userInitiated
                
                // Add operation to the public database
                publicCloudDatabase.add(operation)
            }
        }
    }
    
    /**
     A function to upload the cached records that failed to save or delete due to unforseen
     network circumstances or unexpected crashes.
     
     - parameter recordsToSave: A sequence of records to be saved in the cloud.
     - parameter recordIDsToDelete: A sequence of IDs of managedObjects to be deleted from the cloud.
     */
    static func uploadCachedRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecordID]) {
        
        // Split the records in chunks
        let recordsChunks = recordsToSave.chunks(400)
        
        // For each record chunk
        for records in recordsChunks {
            
            // Run async
            DispatchQueue.main.async {
                
                // Create a modify operation
                let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordsChunks.index(of: records) == recordsChunks.startIndex ? recordIDsToDelete : nil)
                
                // Save the name for UI purposes
                operation.name = "\(String(describing: recordsChunks.index(of: records)?.advanced(by: 1)))"
                
                // Update all keys
                operation.savePolicy = .allKeys
                
                // Completion block to debug errors
                operation.perRecordCompletionBlock = { record, error in
                    if let error = error as? CKError {
                        MapViewController.devLog(data: error.localizedDescription)
                    }
                }
                
                // Completion block to debug errors
                operation.modifyRecordsCompletionBlock = { record, recordID, error in
                    if let error = error as? CKError {
                        if error.code == CKError.limitExceeded {
                            MapViewController.devLog(data: "Modify limit exceeded.")
                        } else {
                            MapViewController.devLog(data: error.localizedDescription)
                        }
                    }
                }
                
                // Completion block for UI feedback
                operation.completionBlock = {
                    MapViewController.devLog(data: "Finished uploading cached records to the cloud. (\(operation.name ?? "")/\(recordsChunks.count))")
                }
                
                // Set the quality of service
                operation.qualityOfService = .userInitiated
                
                // Add the operation to the public database
                publicCloudDatabase.add(operation)
            }
        }
    }
    
    /**
     A function to clear the cached records from the cache context of the local database.
     
     - parameter recordNames: The names of the records that are cached for updating the cloud.
     - parameter completion: A completion block that returns the objectIDs of the cached objects.
     */
    static func clearCachedRecords(recordNames: [String], completion: (([NSManagedObjectID]) -> Void)?) {
        
        // Perform action on the cache context
        cacheContext.perform {
            
            // For each record name
            for recordName in recordNames {
                
                // If the cached record exists in the cached context
                if let objects = objects(entityName: "CachedRecords", in: cacheContext, withRecordName: recordName) {
                    
                    // For each object
                    for object in objects {
                        
                        // Delete the object
                        cacheContext.delete(object as! NSManagedObject)
                    }
                }
            }
            
            // Save the cache context
            PersistenceService.saveCacheContext()
            
            let cachedRecords = objects(entityName: "CachedRecords", in: cacheContext)
            if let objects = cachedRecords, objects.count > 0 {
                
                // Completion with the object IDs of the cached objects.
                completion?(objects.map({ $0.objectID }))
            }
        }
    }
    
    /**
     A function to update the local records from the cloud.
     
     - parameter from recordID: The record ID to be updated.
     - parameter reason: The reason this record should be updated based on the notification.
     */
    static func updateLocalRecord(from recordID: CKRecordID, reason: CKQueryNotificationReason) {
        
        // If the reason was created or updated
        if reason == .recordCreated || reason == .recordUpdated {
            
            // Fetch the record from the cloud
            publicCloudDatabase.fetch(withRecordID: recordID) { (record, error) in
                if let _ = error {
                    MapViewController.devLog(data: "Error while fetching in updateLocalRecord.")
                } else {
                    
                    // If record has been found
                    if let record = record {
                        
                        // Update the object in the update context of the local database
                        updateContext.perform {
                            
                            // Update the object locally
                            updateObject(for: [record])
                            
                            // Save the update context which commits the changes to the view context
                            PersistenceService.saveUpdateContext()
                            
                            // Reload all views for the record type
                            if let dotIndex = recordID.recordName.index(of: ".") {
                                let recordType = String(recordID.recordName[...recordID.recordName.index(before: dotIndex)])
                                MapViewController.reloadView(recordType: recordType)
                            }
                        }
                    }
                }
            }
            
        // If the reason is that the record was deleted
        } else if reason == .recordDeleted {
            
            // Update the object in the update context of the local database
            updateContext.perform {
                
                // Delete the object based on its' record name
                deleteObject(recordNames: [recordID.recordName])
                
                // Save the update context in the local database
                PersistenceService.saveUpdateContext()
                
                // Reload all views for the record type
                if let dotIndex = recordID.recordName.index(of: ".") {
                    let recordType = String(recordID.recordName[...recordID.recordName.index(before: dotIndex)])
                    MapViewController.reloadView(recordType: recordType)
                }
            }
        }
    }
    
    /**
     A function to update a list of objects.
     
     - parameter changedRecords: A sequence of records to be updated in the local database.
     - parameter deletedRecordIDs: A sequence of records to be deleted from the local database.
     */
    static func updateLocalRecords(changedRecords: [CKRecord], deletedRecordIDs: [CKRecordID]?) {
        
        // Update the objects in the update context of the local database
        updateContext.perform {
            
            // Update the object
            updateObject(for: changedRecords)
            
            // Delete the objects based on the record names
            if let deletedRecordIDs = deletedRecordIDs, deletedRecordIDs.count > 0 {
                let deletedRecordNames = deletedRecordIDs.map { $0.recordName }
                deleteObject(recordNames: deletedRecordNames)
            }
            
            // Save the update context in the local database
            PersistenceService.saveUpdateContext()
        }
    }
    
    /**
     A function to fetch data from the cloud.
     
     - parameter completion: A void function that is called when all data has been fetched from the cloud.
     */
    static func fetchDataFromTheCloud(completion: (() -> Void)?) {
        
        // Update the view
        MapViewController.progressView.setProgress(to: 0)
        
        // Load in the background
        DispatchQueue.global(qos: .userInteractive).async {
            
            // Query the floor
            query(recordType: DataClasses.floor.rawValue) { (_) in
                
                // Query the room
                query(recordType: DataClasses.room.rawValue) { (_) in
                    
                    // Query the tiles
                    query(recordType: DataClasses.tile.rawValue) { (completed) in
                        
                        // Query the access points
                        query(recordType: DataClasses.accessPoint.rawValue) { (completed) in
                            
                            // Call the completion block
                            completion?()
                        }
                    }
                }
            }
        }
    }
}
