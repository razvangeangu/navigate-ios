//
//  RGSharedDataManagerFloorExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

extension RGSharedDataManager {
    
    /**
     Sets the current floor
     */
    static func setFloor(level: Int) {
        guard let floor = getFloor(level: level) else { return }
        RGSharedDataManager.floor = floor
    }
    
    /**
     Add floor to the CoreData.
     
     - parameter level: The floor level.
     - parameter mapImage: The image for the map as **NSData**.
     
     - Returns: **true** if floor has been created, **false** otherwise.
     */
    static func addFloor(level: Int, mapImage: NSData) -> Bool {
        
        // If the floor exists stop creating a new one
        if let _ = getFloor(level: level) { return false }
        
        // Create new floor
        let floor = Floor(context: PersistenceService.context)
        
        // Set the level
        floor.level = Int16(level)
        floor.image = mapImage
        
        // Save the context for CoreData
        PersistenceService.saveContext()
        
        return true
    }
    
    /**
     Get from CoreData and set the current floor.
     
     - parameter level: The floor level.
     
     - Returns: A **Floor?** object for the specified level.
     */
    static func getFloor(level: Int) -> Floor? {
        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        do {
            // Get all the floors from CoreData
            let floors = try PersistenceService.context.fetch(fetchRequest)
            for floor in floors {
                
                // Find the floor for the specified level
                if floor.level == level {
                    return floor
                }
            }
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    /**
     A method that gets all the floors from CoreData.
     
     - Returns: An array of **Floor** objects.
     */
    static func getFloors() -> [Floor]? {
        var floors = [Floor]()
        
        let fetchRequest: NSFetchRequest<Floor> = Floor.fetchRequest()
        do {
            // Get all the floors from CoreData
            floors = try PersistenceService.context.fetch(fetchRequest) as [Floor]
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return floors
    }
    
    /**
     Removes a floor that matches the level from the core data.
     
     - parameter with floorLevel: The floor level to be removed
     
     - Returns: **true** if successfully removes the floor, **false** otherwise
     */
    static func removeFloor(with floorLevel: Int) -> Bool {
        if let foundFloor = getFloor(level: floorLevel) {
            PersistenceService.context.delete(foundFloor)
            return true
        }
        
        return false
    }
}
