//
//  CloudKitManagedObject.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CloudKit

@objc protocol CloudKitManagedObject {
    var recordID: Data? { get set }
    var recordName: String? { get set }
    var recordType: String { get }
    var lastUpdate: Data? { get set }
    
    func managedObjectToRecord() -> CKRecord
}

extension CloudKitManagedObject {
    var customZone: CKRecordZone { return CKRecordZone.default() }
    
    func prepareForCloudKit() {
        let uuid = UUID()
        recordName = recordType + "." + uuid.uuidString
        let _recordID = CKRecordID(recordName: recordName!, zoneID: customZone.zoneID)
        recordID = NSKeyedArchiver.archivedData(withRootObject: _recordID)
    }
    
    func cloudKitRecord() -> CKRecord {
        return CKRecord(recordType: recordType, recordID: cloudKitRecordID())
    }
    
    func cloudKitRecordID() -> CKRecordID {
        return NSKeyedUnarchiver.unarchiveObject(with: recordID!) as! CKRecordID
    }
}