//
//  RGSharedDataManagerCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

extension RGSharedDataManager {
    
    static let publicCloudDatabase = CKContainer.default().publicCloudDatabase
    
    static func getFromCloud() {
        let query = CKQuery(recordType: "Floor", predicate: NSPredicate(value: true))
        publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            guard error == nil else {
                MapViewController.devLog(data: "Error in getting data from the cloud.")
                
                return
            }
            
            guard records != nil else {
                MapViewController.devLog(data: "No records found on the cloud.")
                
                return
            }
            
            for record in records! {
                print(record.value(forKey: "data") ?? "")
            }
            
            MapViewController.devLog(data: "Data downloaded from the Cloud.")
        }
    }
    
    static func uploadChangedObjects(savedIDs: [NSManagedObjectID], deletedIDs: [CKRecordID]?) {
        var savedObjects = [CloudKitManagedObject]()
        
        for savedID in savedIDs {
            let savedObject = PersistenceService.context.object(with: savedID) as! CloudKitManagedObject
            savedObjects.append(savedObject)
        }
        
        let records = savedObjects.map({ $0.managedObjectToRecord() }).chunks(400)
        
        for recordsToSave in records {
            let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: deletedIDs)
            operation.perRecordProgressBlock = { _, progress in
                if progress <= 1 {
                    MapViewController.devLog(data: "Uploading block of records")
                }
            }
            operation.modifyRecordsCompletionBlock = { record, recordID, error in
                if let error = error as? CKError {
                    if error.code == CKError.limitExceeded {
                        print("Modify limit exceeded")
                    }
                } else {
                    MapViewController.devLog(data: "Uploaded block of records")
                }
            }
            publicCloudDatabase.add(operation)
        }
    }
}
