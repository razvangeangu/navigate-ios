//
//  TileCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit

extension Tile: CloudKitManagedObject {
    var recordType: String {
        return "Tile"
    }
    
    func managedObjectToRecord() -> CKRecord {
        let tileRecord = cloudKitRecord()
        tileRecord["row"] = row as CKRecordValue
        tileRecord["col"] = col as CKRecordValue
        tileRecord["type"] = type! as CKRecordValue
        tileRecord["lastUpdate"] = lastUpdate! as CKRecordValue
        
        let floorID = floor!.cloudKitRecordID()
        let floorReference = CKReference(recordID: floorID, action: .deleteSelf)
        tileRecord["floorReference"] = floorReference
        
        let roomID = room!.cloudKitRecordID()
        let roomReference = CKReference(recordID: roomID, action: .deleteSelf)
        tileRecord["roomReference"] = roomReference
        
        return tileRecord
    }
}
