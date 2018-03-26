//
//  RoomCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit

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
}
