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
    
    /**
     A function that subscribes to changes of the local record types to update in the background the local database.
     
     - parameter completion: Is a completion block that returns a **Bool* that represents the success of the subscribe operation.
     */
    static func subscribeToChanges(completion: @escaping (_ success: Bool) -> Void) {
        
        // Init the record types to subscribe for
        let recordTypes = [DataClasses.floor.rawValue, DataClasses.room.rawValue, DataClasses.tile.rawValue, DataClasses.accessPoint.rawValue]
        
        // For each record type
        for recordType in recordTypes {
            
            // Create a subscription ID
            let subscriptionID = "\(recordType)Changes"
            
            // Check if the subscription exists
            publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
                
                // If the subscription exists
                if error == nil && subscription != nil {
                    
                    // Call the completion block with true
                    completion(true)
                } else {
                    
                    // Create a subscription query with relevant options
                    let subscription = CKQuerySubscription(recordType: recordType, predicate: NSPredicate(value: true), subscriptionID: subscriptionID, options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
                    
                    // Create the notification info
                    let notificationInfo = CKNotificationInfo()
                    notificationInfo.shouldBadge = false
                    notificationInfo.shouldSendContentAvailable = true
                    
                    // Set the notification info
                    subscription.notificationInfo = notificationInfo
                    
                    // Save the subscription in the cloud database
                    publicCloudDatabase.save(subscription, completionHandler: { (subscription, error) in
                        
                        // Call the completion block with the result of the operation
                        completion(error == nil || subscription != nil)
                    })
                }
            }
        }
    }
}
