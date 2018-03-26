//
//  AccessPointCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit
import CoreData

extension AccessPoint: CloudKitManagedObject {
    var recordType: String {
        return "AccessPoint"
    }
    
    func managedObjectToRecord() -> CKRecord {
        let accessPointRecord = cloudKitRecord()
        accessPointRecord["strength"] = strength as CKRecordValue
        accessPointRecord["uuid"] = uuid! as CKRecordValue
        accessPointRecord["lastUpdate"] = lastUpdate! as CKRecordValue
        
        let tileID = tile!.cloudKitRecordID()
        let tileReference = CKReference(recordID: tileID, action: .deleteSelf)
        accessPointRecord["tileReference"] = tileReference
        
        return accessPointRecord
    }
    
    func update(with record: CKRecord) {
        strength = record["strength"] as! Int64
        uuid = record["uuid"] as? String
        lastUpdate = record["lastUpdate"] as? NSDate
        
        if let tileReference = record["floorReference"] as? CKReference {
            let tileName = tileReference.recordID.recordName
            if let _tile = PersistenceService.object(from: "Tile", in: PersistenceService.updateContext, withRecordName: tileName) as? Tile {
                tile = _tile
            } else {
                if let _newTile = NSEntityDescription.insertNewObject(forEntityName: "Tile", into: PersistenceService.updateContext) as? Tile {
                    _newTile.recordName = tileName
                    tile = _newTile
                }
            }
        }
        
        recordName = record.recordID.recordName
        recordID = NSKeyedArchiver.archivedData(withRootObject: record.recordID) as NSData
    }
}
