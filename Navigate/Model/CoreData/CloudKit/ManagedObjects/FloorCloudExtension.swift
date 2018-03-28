//
//  FloorCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit

extension Floor: CloudKitManagedObject {
    var recordType: String {
        return "Floor"
    }
    
    func managedObjectToRecord() -> CKRecord {
        let floorRecord = cloudKitRecord()
        floorRecord["level"] = level as CKRecordValue
        floorRecord["image"] = image! as CKRecordValue
        floorRecord["lastUpdate"] = lastUpdate! as CKRecordValue
        
        return floorRecord
    }
    
    func update(with record: CKRecord) {
        level = record["level"] as! Int16
        image = record["image"] as? NSData
        lastUpdate = record["lastUpdate"] as? NSDate
        recordName = record.recordID.recordName
        recordID = NSKeyedArchiver.archivedData(withRootObject: record.recordID) as NSData
    }
}
