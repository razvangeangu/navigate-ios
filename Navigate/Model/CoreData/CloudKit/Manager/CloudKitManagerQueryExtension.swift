//
//  CloudKitManagerQueryExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 28/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//  https://stackoverflow.com/questions/28402846/cloudkit-fetch-all-records-with-a-certain-record-type

import Foundation
import CloudKit

extension CloudKitManager {
    
    static func query(recordType: String, completion: ((Bool) -> Void)?) {
        var records = [CKRecord]()
        
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.zoneID = CKRecordZone.default().zoneID
        
        queryOperation.recordFetchedBlock = { record in
            records.append(record)
        }
        
        queryOperation.queryCompletionBlock = { cursor, error in
            self.fetchRecords(with: cursor, error: error, records: records, completion: { (records) in
                updateLocalRecords(changedRecords: records, deletedRecordIDs: nil)
                
                // Update progress view
                MapViewController.progressView.addToProgress(value: 1/4)
                
                completion?(records.count > 0)
            })
        }
        
        queryOperation.completionBlock = {
            MapViewController.devLog(data: "Finished query for \(recordType)")
        }
        
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 500
        queryOperation.qualityOfService = .userInitiated
        
        publicCloudDatabase.add(queryOperation)
    }
    
    private static func fetchRecords(with cursor: CKQueryCursor?, error: Error?, records: [CKRecord], completion: (([CKRecord]) -> Void)?) {
        var currentRecords = records
        if let cursor = cursor, error == nil {
            let queryOperation = CKQueryOperation(cursor: cursor)
            
            queryOperation.recordFetchedBlock = { record in
                currentRecords.append(record)
            }
            queryOperation.queryCompletionBlock = { cursor, error in
                if let error = error {
                    MapViewController.devLog(data: error.localizedDescription)
                }
                
                // Update progress view
                let progress = Float(0.001)
                MapViewController.progressView.addToProgress(value: progress)
                
                MapViewController.devLog(data: "Fetched: \(records.count)")
                self.fetchRecords(with: cursor, error: error, records: currentRecords, completion: completion)
            }
            
            queryOperation.queuePriority = .veryHigh
            queryOperation.resultsLimit = 500
            queryOperation.qualityOfService = .userInitiated
            publicCloudDatabase.add(queryOperation)
        } else {
            completion?(records)
        }
    }
}
