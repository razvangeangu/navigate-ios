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
    static let sharedCloudDatabase = CKContainer.default().sharedCloudDatabase
    static let privateCloudDatabase = CKContainer.default().privateCloudDatabase
    
    static var customSharedZone: CKRecordZone!
    
    static var identities: [CKUserIdentity]!
    
    static var cachedContext = PersistenceService.cacheContext
    static var updateContext = PersistenceService.updateContext
    
    static var serverChangeToken: CKServerChangeToken? {
        let changeTokenData = UserDefaults.standard.value(forKey: "\(customSharedZone.zoneID.zoneName) zoneChangeToken") as? Data
        var zoneChangeToken:CKServerChangeToken?
        
        if (changeTokenData != nil){
            zoneChangeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!)as! CKServerChangeToken?
        }
        
        return zoneChangeToken
    }
    
    /**
     
     
     - parameter savedIDs:
     - parameter deletedIDs:
     */
    static func uploadChangedObjects(savedIDs: [NSManagedObjectID], deletedIDs: [CKRecordID]?) {
        
        // Create var for the saved objects as cloud managed objects
        var savedObjects = [CKRecord]()
        var sharedObjects = [CKShare]()

        // Get all the to save cloud managed objects
        for savedID in savedIDs {
            let savedObject = PersistenceService.viewContext.object(with: savedID) as! CloudKitManagedObject
            let record = savedObject.managedObjectToRecord()
            savedObjects.append(record)
            
            let share = CKShare(rootRecord: record)
            share[CKShareTitleKey] = record.recordID.recordName as CKRecordValue?
            share[CKShareTypeKey] = "com.razvangeangu.Navigate" as CKRecordValue?
            sharedObjects.append(share)
        }
        
        // Split into maximum number of chunks allowed by CloudKit
        let recordsChunks = savedObjects.chunks(400)
        let sharedChunks = sharedObjects.chunks(400)
        
        for chunkID in 0..<recordsChunks.count {
            
            // Create a new modify records operation
            let operation = CKModifyRecordsOperation(recordsToSave: recordsChunks[chunkID] + sharedChunks[chunkID], recordIDsToDelete: chunkID == 0 ? deletedIDs : nil)
            
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
                                                debugPrint("Saved to cache context, remember to update cloud.")
                                            } catch {
                                                debugPrint("Could not save \(cachedRecord.recordName ?? "cachedRecord")")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    debugPrint(error ?? "Error in upload changed objects")
                }
            }
            
            // Set the completion handler for the operation
            operation.modifyRecordsCompletionBlock = { records, recordsID, error in
                
                // If there is an error
                if let error = error as? CKError {
                    
                    if error.code == .limitExceeded {
                        debugPrint("Modify limit exceeded")
                        
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
                                        let recordID = CKRecordID(recordName: recordName, zoneID: customSharedZone.zoneID)
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
                            debugPrint("Error in fetchRequest for CachedRecords.")
                        }
                    } else {
                        debugPrint(error)
                    }
                }
            }
            
            operation.completionBlock = {
                debugPrint("Finished uploading changed objects to the cloud.")
            }
            
            // Add operation to the public database
            privateCloudDatabase.add(operation)
        }
    }
    
    static func uploadCachedRecords(recordsToSave: [CKRecord], recordIDsToDelete: [CKRecordID]) {
        let recordsChunks = recordsToSave.chunks(400)
        for records in recordsChunks {
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: recordsChunks.index(of: records) == recordsChunks.startIndex ? recordIDsToDelete : nil)
            operation.savePolicy = .allKeys
            
            operation.perRecordCompletionBlock = { record, error in
                if let error = error as? CKError {
                    debugPrint(error)
                }
            }
            
            operation.modifyRecordsCompletionBlock = { record, recordID, error in
                if let error = error as? CKError {
                    if error.code == CKError.limitExceeded {
                        debugPrint("Modify limit exceeded.")
                    } else {
                        debugPrint(error)
                    }
                }
            }
            
            operation.completionBlock = {
                debugPrint("Finished uploading cached records to the cloud.")
            }
            
            privateCloudDatabase.add(operation)
        }
    }
    
    // https://stackoverflow.com/questions/28402846/cloudkit-fetch-all-records-with-a-certain-record-type
    static func query(recordType: String, completion: ((Bool) -> Void)?) {
        var records = [CKRecord]()
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.zoneID = customSharedZone.zoneID
        queryOperation.resultsLimit = 500
        
        queryOperation.recordFetchedBlock = { record in
            records.append(record)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            self.fetchRecords(with: cursor, error: error, records: records, completion: { (records) in
                PersistenceService.updateLocalRecords(changedRecords: records, deletedRecordIDs: nil)
                completion?(records.count > 0)
            })
        }
        
        queryOperation.completionBlock = {
            debugPrint("Finished query for \(recordType)")
        }
        
        privateCloudDatabase.add(queryOperation)
    }
    
    // https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/CloudKitQuickStart/MaintainingaLocalCacheofCloudKitRecords/MaintainingaLocalCacheofCloudKitRecords.html
    static func fetchDatabaseChanges(database: CKDatabase, completion: @escaping () -> Void) {
        var changedZoneIDs: [CKRecordZoneID] = []
        
        let previousServerChangeToken = RGSharedDataManager.serverChangeToken!
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: previousServerChangeToken)
        
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        
        operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
            // Write this zone deletion to memory
        }
        
        operation.changeTokenUpdatedBlock = { (token) in
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
        }
        
        operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
            if let error = error {
                debugPrint("Error during fetch shared database changes operation", error)
                completion()
                return
            }
            // Flush zone deletions for this database to disk
            // Write this new database change token to memory
            
            self.fetchZoneChanges(database: database, previousServerChangeToken: previousServerChangeToken, zoneIDs: changedZoneIDs) {
                // Flush in-memory database change token to disk
                completion()
            }
        }
        operation.qualityOfService = .userInitiated
        
        database.add(operation)
    }
    
    static func fetchZoneChanges(database: CKDatabase, previousServerChangeToken: CKServerChangeToken, zoneIDs: [CKRecordZoneID], completion: @escaping () -> Void) {
        
        var optionsByRecordZoneID = [CKRecordZoneID: CKFetchRecordZoneChangesOptions]()
        let options = CKFetchRecordZoneChangesOptions()
        options.previousServerChangeToken = previousServerChangeToken
        optionsByRecordZoneID[customSharedZone.zoneID] = options

        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [RGSharedDataManager.customSharedZone.zoneID], optionsByRecordZoneID: optionsByRecordZoneID)
        
        operation.recordChangedBlock = { (record) in
            debugPrint("Record changed:", record)
            // Write this record change to memory
        }
        
        operation.recordWithIDWasDeletedBlock = { (recordId, _) in
            debugPrint("Record deleted:", recordId)
            // Write this record deletion to memory
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
        }
        
        operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, _, _, error) in
            if let error = error {
                debugPrint("Error fetching zone changes for database:", error)
                return
            }
            // Flush record changes and deletions for this zone to disk
            // Write this new zone change token to disk
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { (error) in
            if let error = error {
                debugPrint("Error fetching zone changes for database:", error)
            }
            completion()
        }
        
        database.add(operation)
    }
    
    private static func fetchRecords(with cursor: CKQueryCursor?, error: Error?, records: [CKRecord], completion: (([CKRecord]) -> Void)?) {
        var currentRecords = records
        if let cursor = cursor, error == nil {
            let queryOperation = CKQueryOperation(cursor: cursor)
            queryOperation.resultsLimit = 500
            queryOperation.recordFetchedBlock = { record in
                currentRecords.append(record)
            }
            queryOperation.queryCompletionBlock = { cursor, error in
                if let error = error {
                    debugPrint(error)
                }
                
                debugPrint("\(records.count)")
                self.fetchRecords(with: cursor, error: error, records: currentRecords, completion: completion)
            }
            privateCloudDatabase.add(queryOperation)
        } else {
            completion?(records)
        }
    }
    
    static func createSubscription() {
        let subscription = CKRecordZoneSubscription(zoneID: customSharedZone.zoneID, subscriptionID: "cloudChangesSub")
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let subscriptionOperation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        subscriptionOperation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            if let error = error {
                NSLog("CloudKit ModifySubscriptions Error: \(error.localizedDescription)")
            } else {
                UserDefaults.standard.set(true, forKey: "cloudChangesSub")
            }
        }
        privateCloudDatabase.add(subscriptionOperation)
    }
    
    static func createCustomZone(completion: (() -> Void)?) {
        let customZone = CKRecordZone(zoneID: CKRecordZoneID(zoneName: "shared-navigate-zone", ownerName: CKCurrentUserDefaultName))
        let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [] )
        
        createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
            if (error == nil) {
                RGSharedDataManager.customSharedZone = customZone
                completion?()
            } else {
                debugPrint(error ?? "Error in create custom zone")
            }
        }
        createZoneOperation.qualityOfService = .userInitiated
        
        RGSharedDataManager.sharedCloudDatabase.add(createZoneOperation)
    }
    
    static func getCustomZone(completion: @escaping ((Bool) -> Void)) {
        RGSharedDataManager.sharedCloudDatabase.fetchAllRecordZones { (zones, error) in
            if let error = error {
                debugPrint(error)
                completion(false)
            } else {
                if let zones = zones {
                    for zone in zones {
                        if zone.zoneID.zoneName == "shared-navigate-zone" {
                            RGSharedDataManager.customSharedZone = zone
                            completion(true)
                        }
                    }
                }
            }
        }
    }
}
