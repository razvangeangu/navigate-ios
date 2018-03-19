//
//  RGSharedDataManagerBLEExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

extension RGSharedDataManager {
    
    /**
     Write a command to the terminal of the external device.
     
     - parameter command: A string that represents the command to be executed by the external device.
     */
    static func writeToTerminal(command: String) {
        ble.write(command: command)
    }
    
    /**
     Connect to an external device using a UUID.
     
     - parameter to: UUID as string.
     */
    static func connect(to: String) {
        ble.connect(to: to)
    }
    
    /**
     Shutdown external device.
     */
    static func disconnect() {
        RGSharedDataManager.ble.stopPi()
    }
    
    /**
     A method to get the APs from the external device and save them to the context.
     
     - Returns: An **NSSet?** containing the APs.
     */
    static func getAccessPoints() -> NSSet? {
        let accessPoints = NSMutableSet()
        
        // Get the APs from the external device as an Array of Any
        guard let jsonObject = jsonData as? [[Any]] else { return accessPoints }
        
        // Get every AP from the Array
        for accessPoint in jsonObject {
            
            // Get the properties
            let address = String.init(describing: accessPoint[0])
            let strength = Int64.init(exactly: accessPoint[1] as! NSNumber)!
            
            // Create a new access point and save it to the CoreData context
            let ap = AccessPoint(context: PersistenceService.context)
            ap.uuid = address
            ap.strength = strength
            accessPoints.add(ap)
        }
        
        return accessPoints
    }
}
