//
//  RGSharedDataManagerFloorExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

extension RGSharedDataManager {
    static func setFloor(level: Int) {
        guard let floor = getFloor(level: level) else { return }
        RGSharedDataManager.floor = floor
    }
    
    /**
     Add floor to the CoreData.
     
     - parameter level: The floor level.
     */
    static func addFloor(level: Int, mapImage: NSData) {
        
        // If the floor exists stop creating a new one
        if let _ = getFloor(level: level) { return }
        
        // Create new floor
        let floor = Floor(context: PersistenceService.context)
        
        // Set the level
        floor.level = Int16(level)
        floor.image = mapImage
        
        // Save the context for CoreData
        PersistenceService.saveContext()
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
        
        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        do {
            // Get all the floors from CoreData
            floors = try PersistenceService.context.fetch(fetchRequest) as [Floor]
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return floors
    }
}
