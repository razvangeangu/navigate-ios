//
//  RGSharedDataManagerAccessPointExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

extension RGSharedDataManager {
    
    /**
     A method to get the APs from the external device and without saving them to the context.
     
     - Returns: An **NSSet?** containing the APs.
     */
    static func getAccessPoints() -> [AccessPoint]? {
        // Get the APs from the external device as an Array of Any
        guard let jsonObject = jsonData as? [[Any]] else { return nil }
        
        var accessPoints = [AccessPoint]()
        
        // Get every AP from the Array
        for accessPoint in jsonObject {
            
            // Get the properties
            let address = String.init(describing: accessPoint[0])
            let strength = Int64.init(exactly: accessPoint[1] as! NSNumber)!
            
            // Create a new access point
            let ap = AccessPoint(entity: AccessPoint.entity(), insertInto: nil)
            ap.uuid = address
            ap.strength = strength
            ap.lastUpdate = NSDate()
            accessPoints.append(ap)
        }
        
        return accessPoints
    }
    
    /**
     A method that creates an Access Point without adding it to the local/cloud database.
     
     - parameter address: The unique address of the Access Point (UUID) as String.
     - parameter strength: The strength of the Access Point at the moment of recognition.
     - parameter tile: The tile of the Access Point.
     
     - Returns: An **AccessPoint** object.
     */
    static func createAccessPoint(address: String, strength: Int64, tile: Tile) -> AccessPoint {
        // Create a new access point
        let accessPoint = AccessPoint(context: PersistenceService.viewContext)
        accessPoint.prepareForCloudKit()
        accessPoint.uuid = address
        accessPoint.strength = strength
        accessPoint.lastUpdate = NSDate()
        tile.addToAccessPoints(accessPoint)
        
        return accessPoint
    }
}
