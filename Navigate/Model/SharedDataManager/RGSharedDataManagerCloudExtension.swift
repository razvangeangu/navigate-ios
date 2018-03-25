//
//  RGSharedDataManagerCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit

extension RGSharedDataManager {
    
    static let database = CKContainer.default().publicCloudDatabase
    
    static func saveToCloud() {
        let newRecord = CKRecord(recordType: "Floor")
        newRecord.setValue(self.encodeData(), forKey: "data")
        
        database.save(newRecord) { (record, error) in
            guard record != nil && error == nil else {
                DispatchQueue.main.async {
                    MapViewController.devLog(data: "Error in saving to the cloud.")
                }
                
                return
            }
            
            DispatchQueue.main.async {
                MapViewController.devLog(data: "Data saved to Cloud.")
            }
        }
    }
    
    static func getFromCloud() {
        let query = CKQuery(recordType: "Floor", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { (records, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    MapViewController.devLog(data: "Error in getting data from the cloud.")
                }
                
                return
            }
            
            guard records != nil else {
                DispatchQueue.main.async {
                    MapViewController.devLog(data: "No records found on the cloud.")
                }
                
                return
            }
            
            for record in records! {
                print(record.value(forKey: "data") ?? "")
            }
            
            DispatchQueue.main.async {
                MapViewController.devLog(data: "Data downloaded from the Cloud.")
            }
        }
    }
}
