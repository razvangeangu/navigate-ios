//
//  TileCloudExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit
import CoreData

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
    
    func update(with record: CKRecord) {
        row = record["row"] as! Int16
        col = record["col"] as! Int16
        type = record["type"] as? String
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
        
        if let roomReference = record["roomReference"] as? CKReference {
            let roomName = roomReference.recordID.recordName
            if let _room = CloudKitManager.object(in: CloudKitManager.updateContext, recordName: roomName) as? Room {
                room = _room
            } else {
                if let _newRoom = NSEntityDescription.insertNewObject(forEntityName: "Room", into: CloudKitManager.updateContext) as? Room {
                    _newRoom.recordName = roomName
                    room = _newRoom
                }
            }
        }
        
        recordName = record.recordID.recordName
        recordID = NSKeyedArchiver.archivedData(withRootObject: record.recordID) as NSData
    }
}
