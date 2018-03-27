//
//  RGSharedDataManagerCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
// https://tongtian.wordpress.com/2017/03/04/sync-core-data-with-cloudkit-part-2/

import Foundation
import CoreData
import CloudKit

extension RGSharedDataManager {
    
    static let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    static let privateCloudDatabase = CKContainer.default().privateCloudDatabase
    static let publicZone = CKRecordZone.default()
    
    static var cachedContext = PersistenceService.cacheContext
    static var updateContext = PersistenceService.updateContext
    
    /**
     
     
     - parameter savedIDs:
     - parameter deletedIDs:
     */
    static func uploadChangedObjects(savedIDs: [NSManagedObjectID], deletedIDs: [CKRecordID]?) {
        
        // Create var for the saved objects as cloud managed objects
        var savedObjects = [CloudKitManagedObject]()

        // Get all the to save cloud managed objects
        for savedID in savedIDs {
            let savedObject = PersistenceService.viewContext.object(with: savedID) as! CloudKitManagedObject
            savedObjects.append(savedObject)
        }
        
        // Split into maximum number of chunks allowed by CloudKit
        let recordsChunks = savedObjects.map({ $0.managedObjectToRecord() }).chunks(400)
        for records in recordsChunks {
            
            // Create a new modify records operation
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordsChunks.index(of: records) == recordsChunks.startIndex ? deletedIDs : nil)
            
            // Set the name of the operation for completion handler
            operation.name = String(recordsChunks.index(of: records)!)
            
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
                                        let cachedRecord = CachedRecords(context: cachedContext)
                                        cachedRecord.recordName = clientRecord.recordID.recordName
                                        cachedRecord.modificationDate = NSDate()
                                        
                                        // Save the cache context
                                        if cachedContext.hasChanges {
                                            do {
                                                try cachedContext.save()
                                                print("Saved to cache context, remember to update cloud.")
                                            } catch {
                                                print("Could not save \(cachedRecord.recordName ?? "cachedRecord")")
                                            }
                                        }
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
                        print("Modify limit exceeded")
                        
                    // If app had partial failure, update the cached records to overwrite the changes
                    } else if error.code == .partialFailure {
                        do {
                            
                            // get the cached records from the cached context
                            let cachedRecords = try cachedContext.fetch(NSFetchRequest(entityName: "CachedRecords"))
                            
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
                                    let managedObject = PersistenceService.object(in: PersistenceService.viewContext, recordName: recordName)
                                    
                                    // Cast to cloud managed object
                                    if let cloudManagedObject = managedObject as? CloudKitManagedObject {
                                        
                                        // Get the record and add it to the var
                                        let record = cloudManagedObject.managedObjectToRecord()
                                        recordsToSave.append(record)
                                    } else {
                                        
                                        // If the record is existent anymore, we want to delete it from the cloud
                                        let recordID = CKRecordID(recordName: recordName, zoneID: publicZone.zoneID)
                                        recordIDsToDelete.append(recordID)
                                    }
                                }
                                
                                // Clear the cached records from the context
                                PersistenceService.clearCachedRecords(recordNames: recordNames, completion: { (_) in
                                    
                                    // Update iCloud database
                                    uploadCachedRecords(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
                                })
                            }
                        } catch {
                            print("Error in fetchRequest for CachedRecords")
                        }
                    } else {
                        print(error.localizedDescription)
                    }
                } else {
                    
                    // If this is the end of the operation
                    if operation.name == String(recordsChunks.endIndex) {
                        print("Finished uploading changed objects to the cloud.")
                    }
                }
            }
            
            // Add operation to the public database
            publicCloudDatabase.add(operation)
        }
    }
    
    // https://stackoverflow.com/questions/28402846/cloudkit-fetch-all-records-with-a-certain-record-type
    static func query(recordType: String, completion: ((Bool) -> Void)?) {
        var records = [CKRecord]()
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.zoneID = publicZone.zoneID
        queryOperation.resultsLimit = 400
        queryOperation.recordFetchedBlock = { record in
            records.append(record)
        }
        queryOperation.queryCompletionBlock = { cursor, error in
            self.fetchRecords(with: cursor, error: error, records: records, completion: { (records) in
                PersistenceService.updateLocalRecords(changedRecords: records, deletedRecordIDs: nil)
                completion?(records.count > 0)
            })
        }
        publicCloudDatabase.add(queryOperation)
    }
    
    private static func fetchRecords(with cursor: CKQueryCursor?, error: Error?, records: [CKRecord], completion: (([CKRecord]) -> Void)?) {
        var currentRecords = records
        if let cursor = cursor, error == nil {
            let queryOperation = CKQueryOperation(cursor: cursor)
            queryOperation.resultsLimit = 400
            queryOperation.recordFetchedBlock = { record in
                currentRecords.append(record)
            }
            queryOperation.queryCompletionBlock = { cursor, error in
                print("\(records.count)")
                self.fetchRecords(with: cursor, error: error, records: currentRecords, completion: completion)
            }
            publicCloudDatabase.add(queryOperation)
        } else {
            completion?(records)
        }
    }
    
    static func uploadCachedRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecordID]) {
        let recordsChunks = recordsToSave.chunks(400)
        for records in recordsChunks {
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordsChunks.index(of: records) == recordsChunks.startIndex ? recordIDsToDelete : nil)
            operation.name = String(recordsChunks.index(of: recordsToSave)!)
            operation.savePolicy = .changedKeys
            operation.perRecordCompletionBlock = { record, error in
                if let error = error as? CKError {
                    print(error.localizedDescription)
                }
            }
            operation.modifyRecordsCompletionBlock = { record, recordID, error in
                if let error = error as? CKError {
                    if error.code == CKError.limitExceeded {
                        print("Modify limit exceeded")
                    }
                } else {
                    print("Uploaded block of cached records")
                }
            }
            publicCloudDatabase.add(operation)
        }
    }
    
    static func createSubscription() {
        let subscription = CKRecordZoneSubscription(zoneID: publicZone.zoneID, subscriptionID: "CachedRecordsSubscriptionID")
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let subscriptionOperation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        subscriptionOperation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            if let error = error {
                NSLog("CloudKit ModifySubscriptions Error: \(error.localizedDescription)")
            } else {
                UserDefaults.standard.set(true, forKey: "CachedRecordsSubscriptionID")
            }
        }
        privateCloudDatabase.add(subscriptionOperation)
    }
}
