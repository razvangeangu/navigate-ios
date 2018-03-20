//
//  RGSharedDataManagerRoomsExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

extension RGSharedDataManager {
    
    /**
     A method that adds a room to CoreData
     
     - parameter name: A string that represents the name of the room
     
     - Returns: **true** if succeeded in adding a room or **false** if it already exists
     */
    static func addRoom(name: String) -> Bool {
        // If the room exists stop
        if let _ = getRoom(name: name, floor: self.floor) { return false }
        
        // Create new room
        let room = Room(context: PersistenceService.context)
        
        // Set the room name
        room.name = name
        
        // Set the room floor
        room.floor = self.floor
        
        // Save the context for CoreData
        PersistenceService.saveContext()
        
        return true
    }
    
    /**
     Gets the room from CoreData by the name and floor.
     
     - parameter name: A string that represents the name of the room
     - parameter floor: The floor of the room.
     
     - Returns: A Room object if it finds the room in CoreData
     */
    static func getRoom(name: String, floor: Floor) -> Room? {
        let fetchRequest : NSFetchRequest<Room> = Room.fetchRequest()
        do {
            // Get all the rooms from CoreData
            let rooms = try PersistenceService.context.fetch(fetchRequest)
            for room in rooms {
                // Find the room for the specified name
                if room.name == name && room.floor == floor {
                    return room
                }
            }
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    /**
     Get the rooms from the current floor.
     
     - Returns: An array of strings that represent the rooms for the current floor.
     */
    static func getRooms() -> [Room]? {
        return floor.rooms!.allObjects as? [Room]
    }
}
