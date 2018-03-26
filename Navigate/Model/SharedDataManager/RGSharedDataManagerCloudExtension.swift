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
    
    static func uploadChangedObjects(savedIDs: [NSManagedObjectID], deletedIDs: [CKRecordID]?) {
        var savedObjects = [CloudKitManagedObject]()
        
        for savedID in savedIDs {
            let savedObject = PersistenceService.viewContext.object(with: savedID) as! CloudKitManagedObject
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
    
    static func uploadCachedRecords(objects: [NSManagedObject]) {
        let _ = objects.map({ ($0 as! CloudKitManagedObject).managedObjectToRecord() }).chunks(30) // TODO: delete
    }
}
