//
//  RoomCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit
import CoreData

extension Room: CloudKitManagedObject {
    var recordType: String {
        return "Room"
    }
    
    func managedObjectToRecord() -> CKRecord {
        let roomRecord = cloudKitRecord()
        roomRecord["name"] = name! as CKRecordValue
        roomRecord["lastUpdate"] = lastUpdate! as CKRecordValue
        
        let floorID = floor!.cloudKitRecordID()
        let floorReference = CKReference(recordID: floorID, action: .deleteSelf)
        roomRecord["floorReference"] = floorReference
        
        return roomRecord
    }
    
    func update(with record: CKRecord) {
        name = record["name"] as? String
        lastUpdate = record["lastUpdate"] as? NSDate
        
        if let floorReference = record["floorReference"] as? CKReference {
            let floorName = floorReference.recordID.recordName
            if let _floor = CloudKitManager.object(in: CloudKitManager.updateContext, recordName: floorName) as? Floor {
                floor = _floor
            } else {
                if let _newFloor = NSEntityDescription.insertNewObject(forEntityName: "Floor", into: CloudKitManager.updateContext) as? Floor {
                    _newFloor.recordName = floorName
                    floor = _newFloor
                }
            }
        }
        
        recordName = record.recordID.recordName
        recordID = NSKeyedArchiver.archivedData(withRootObject: record.recordID) as NSData
    }
}
