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
        if let _ = getRoom(name: name, floor: floor) { return false }
        
        // Create new room
        let room = Room(context: PersistenceService.viewContext)
        room.prepareForCloudKit()
        
        // Set the room name
        room.name = name
        
        // Add floor to room
        floor.addToRooms(room)
        
        // Set the last update time
        room.lastUpdate = NSDate()
        
        // Save the context for CoreData
        PersistenceService.saveViewContext()
        
        return true
    }
    
    /**
     Gets the room from CoreData by the name and floor.
     
     - parameter name: A string that represents the name of the room
     - parameter floor: The floor of the room.
     
     - Returns: A Room object if it finds the room in CoreData
     */
    static func getRoom(name: String, floor: Floor) -> Room? {
        // Check if name is empty.
        if name.isEmpty { return nil }
        
        let fetchRequest : NSFetchRequest<Room> = Room.fetchRequest()
        do {
            // Get all the rooms from CoreData
            let rooms = try PersistenceService.viewContext.fetch(fetchRequest)
            for room in rooms {
                // Find the room for the specified name
                if room.name == name && room.floor == floor {
                    return room
                }
            }
        } catch {
            MapViewController.devLog(data: "Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    /**
     Get the rooms from the current floor.
     
     - Returns: An array of strings that represent the rooms for the current floor.
     */
    static func getRooms() -> [Room]? {
        if let floor = floor {
            return floor.rooms!.allObjects as? [Room]
        } else {
            return nil
        }
    }
    
    /**
     Removes a room that matches the name from the core data.
     
     - parameter with: The room name to be removed
     
     - Returns: **true** if successfully removes the room, **false** otherwise
     */
    static func removeRoom(with roomName: String, floor: Floor) -> Bool {
        if let foundRoom = getRoom(name: roomName, floor: floor) {
            PersistenceService.viewContext.delete(foundRoom)
            return true
        }
        
        return false
    }
    
    /**
     Get the doors for the room.
     
     - parameter for: The room for which the doors (as **Tile**) need to be fine.
     */
    static func getDoors(for room: Room) -> [Tile]? {
        var doors = [Tile]()
        for case let tile as Tile in room.tiles! {
            if tile.type == CDTileType.door.rawValue {
                doors.append(tile)
            }
        }
        
        return doors
    }
}
