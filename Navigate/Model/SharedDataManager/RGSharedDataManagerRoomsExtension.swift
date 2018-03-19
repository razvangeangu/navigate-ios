//
//  RGSharedDataManagerRoomsExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

extension RGSharedDataManager {
    static func addRoom(name: String) -> Bool {
        // If the room exists stop
        if let _ = getRoom(name: name) { return false }
        
        // Create new room
        let room = Room(context: PersistenceService.context)
        
        // Set the room name
        room.name = name
        
        // Set the room floor
        room.floor = floor
        
        // Save the context for CoreData
        PersistenceService.saveContext()
        
        return true
    }
    
    static func getRoom(name: String) -> Room? {
        let fetchRequest : NSFetchRequest<Room> = Room.fetchRequest()
        do {
            // Get all the rooms from CoreData
            let rooms = try PersistenceService.context.fetch(fetchRequest)
            for room in rooms {
                
                // Find the room for the specified name
                if room.name == name {
                    return room
                }
            }
        } catch {
            debugPrint("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    /**
     Get the rooms for the current floor.
     
     - Returns: An array of strings that represent the rooms for the current floor.
     */
    static func getRooms() -> [Room]? {
        return floor.rooms!.allObjects as? [Room]
    }
}
