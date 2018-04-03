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
    
    /**
     A function that queries the cloud database for records of a specific type.
     
     - parameter recordType: A **String** that represents the type of the record the be queried.
     - parameter completion: A **Void** function that returns a **Bool** that represents if records have been found.
     */
    static func query(recordType: String, completion: ((Bool) -> Void)?) {
        
        // Init the sequence of records
        var records = [CKRecord]()
        
        // Create a Query
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        
        // Create a Query Operation
        let queryOperation = CKQueryOperation(query: query)
        
        // Set the zoneID
        queryOperation.zoneID = CKRecordZone.default().zoneID
        
        // Append the cloud record to our sequence for each fetch
        queryOperation.recordFetchedBlock = { record in
            records.append(record)
        }
        
        // Set the query completion block
        queryOperation.queryCompletionBlock = { cursor, error in
            
            // Call recursive method to fetch all objects in the cloud
            self.fetchRecords(with: cursor, error: error, records: records, completion: { (records) in
                
                // Update all the local records based on the fetched cloud records
                updateLocalRecords(changedRecords: records, deletedRecordIDs: nil)
                
                // Update progress view
                MapViewController.progressView.addToProgress(value: 1/4)
                
                // Call the optional completion block and set the **Bool** to true if records have been found
                completion?(records.count > 0)
            })
        }
        
        // Set the completion block for the query
        queryOperation.completionBlock = {
            MapViewController.devLog(data: "Finished query for \(recordType)")
        }
        
        // Set the results limit
        queryOperation.resultsLimit = 500
        
        // Set the quality of service as fast as possible
        queryOperation.qualityOfService = .userInitiated
        
        // Add the query to the public database
        publicCloudDatabase.add(queryOperation)
    }
    
    /**
     A recursive function to fetch records based on a cursor.
     
     - parameter with cursor: The cursor from the last fetch index.
     - parameter error: The error of the query operation.
     - parameter records: A sequence of records that have been accumulated in the recursive calls.
     - parameter completion: An optional completion block that returns the accumulated records.
     */
    private static func fetchRecords(with cursor: CKQueryCursor?, error: Error?, records: [CKRecord], completion: (([CKRecord]) -> Void)?) {
        
        // Init the current records
        var currentRecords = records
        
        // If the cursor did not finish and there are no errors
        if let cursor = cursor, error == nil {
            
            // Create a Query Operation
            let queryOperation = CKQueryOperation(cursor: cursor)
            
            // Set the completion block on record fetched
            queryOperation.recordFetchedBlock = { record in
                
                // Add the record to our current accumulated list
                currentRecords.append(record)
            }
            
            // Set the query completion block
            queryOperation.queryCompletionBlock = { cursor, error in
                
                // If there is an error
                if let error = error {
                    
                    // UI Feedback
                    MapViewController.devLog(data: error.localizedDescription)
                }
                
                // Update progress view
                let progress = Float(0.001)
                MapViewController.progressView.addToProgress(value: progress)
                
                // UI Feedback
                MapViewController.devLog(data: "Fetched: \(records.count)")
                
                // Recursive call
                self.fetchRecords(with: cursor, error: error, records: currentRecords, completion: completion)
            }
            
            // Set the results limit
            queryOperation.resultsLimit = 500
            
            // Set the quality of service to the fastest
            queryOperation.qualityOfService = .userInitiated
            
            // Add the query to the public database
            publicCloudDatabase.add(queryOperation)
        } else {
            
            // Call the completion block if there are errors or cursor finished
            completion?(records)
        }
    }
}
