//
//  CloudKitManagerSubscriptionExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 28/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import CloudKit

extension CloudKitManager {
    
    static func subscribeToChanges(completion: @escaping (_ success: Bool) -> Void) {
        let recordTypes = [DataClasses.floor.rawValue, DataClasses.room.rawValue, DataClasses.tile.rawValue, DataClasses.accessPoint.rawValue]
        
        for recordType in recordTypes {
            let subscriptionID = "\(recordType)Changes"
            
            publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
                if error == nil && subscription != nil {
                    completion(true)
                } else {
                    let subscription = CKQuerySubscription(recordType: recordType, predicate: NSPredicate(value: true), options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
                    
                    let notificationInfo = CKNotificationInfo()
                    notificationInfo.shouldBadge = false
                    notificationInfo.shouldSendContentAvailable = true
                    subscription.notificationInfo = notificationInfo
                    
                    self.publicCloudDatabase.save(subscription, completionHandler: { (subscription, error) in
                        completion(error == nil)
                    })
                }
            }
        }
    }
}
