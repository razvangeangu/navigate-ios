//
//  AccessPointCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit

extension AccessPoint: CloudKitManagedObject {
    var recordType: String {
        return "AccessPoint"
    }
    
    func managedObjectToRecord() -> CKRecord {
        let accessPointRecord = cloudKitRecord()
        accessPointRecord["strength"] = strength as CKRecordValue
        accessPointRecord["uuid"] = uuid! as CKRecordValue
        accessPointRecord["lastUpdate"] = lastUpdate! as CKRecordValue
        
        if let tile = tile {
            let tileID = tile.cloudKitRecordID()
            let tileReference = CKReference(recordID: tileID, action: .deleteSelf)
            accessPointRecord["tileReference"] = tileReference
        }
        
        return accessPointRecord
    }
}
