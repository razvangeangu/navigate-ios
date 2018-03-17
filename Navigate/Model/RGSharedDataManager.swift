//
//  RGSharedDataManager.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

class RGSharedDataManager: NSObject {
    
    static var appMode: AppMode = .prod
    
    // Room information
    static var selectedRoom = ""
    
    // Floor information
    static var floorLevel = 6
    static var floor: Floor!
    
    // Map sizes
    static let numberOfRows = 35
    static let numberOfColumns = 12                                                    
    
    // Bluetooth Low Energy service
    fileprivate static let ble = BLEService()
    
    // Detect location on changing value of the json
    static var jsonData: Any! {
        didSet {
            RGLocalisation.detectLocation()
        }
    }
    
    override init() {
        super.init()
    }
    
    /**
     Connect to an external device using a UUID.
     
     - parameter to: UUID as string
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
     Set the current floor to the specified level.
     It gets it from CoreData or creates a new one if *nil*.
     
     - parameter level: The floor level.
     */
    static func setFloor(level: Int) {
        RGSharedDataManager.floor = getFloor(level: RGSharedDataManager.floorLevel)
        
        // If could not find a floor for the specified level
        if RGSharedDataManager.floor == nil {
            
            // Create new floor
            RGSharedDataManager.floor = Floor(context: PersistenceService.context)
            
            // Set the level
            RGSharedDataManager.floor.level = Int16(level)
            
            // Save the context for CoreData
            PersistenceService.saveContext()
        }
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
            MapViewController.devLog(data: "Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    /**
     A method to get the APs from the external device and save them to the context.
     
     - Returns: An **NSSet?** containing the APs
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
        
        // Save the context for CoreData
        // PersistenceService.saveContext()
        
        return accessPoints
    }
    
    /**
     Saves the data for the tile at the specified location.
     
     - parameter column: The column of the tile *(y index of the tile in database)*
     - parameter row: The row of the tile *(x index of the tile in database)*
     
     - Returns: **true** if the data has been saved successfuly or **false** if could not find APs
     */
    static func saveDataToTile(column: Int, row: Int) -> Bool {
        guard let accessPoints = getAccessPoints() else { return false }
        
        // Create a new tile
        let tile = Tile(context: PersistenceService.context)
        
        // Set the location for the tile
        tile.x = Int16(row)
        tile.y = Int16(column)
        
        // Add the room to the tile
        tile.room = selectedRoom
        
        // Add the APs data
        tile.accessPoints = accessPoints
        
        // Add tile to APs
        for accessPoint in accessPoints {
            (accessPoint as! AccessPoint).addToTiles(tile)
        }
        
        // Set the floor for the tile
        tile.floor = floor
        
        // Add the tile to the floor
        floor.addToTiles(tile)
        
        // Save the context for CoreData
        PersistenceService.saveContext()
        
        return true
    }
    
    /**
     Checks if the tile on the current floor has APs stored and more than 0.
     
     - parameter column: The column of the tile *(y index of the tile in database)*
     - parameter row: The row of the tile *(x index of the tile in database)*
     
     - Returns: **true** data has been found or **false** if could not find APs
    */
    static func accessPointHasData(column: Int, row: Int) -> Bool {
        // Get all the tiles
        for tile in RGSharedDataManager.floor.tiles! {
            
            // If the tile matches
            if (tile as! Tile).x == Int16(row) && (tile as! Tile).y == Int16(column) {
                // Check the number of APs
                return ((tile as! Tile).accessPoints?.count)! > 0
            }
        }
        return false
    }
    
    static func getRooms() -> [String] {
        var rooms = [String]()
        for tile in RGSharedDataManager.floor.tiles! {
            let room = (tile as! Tile).room
            if room != nil && !rooms.contains(room!) {
                rooms.append(room!)
            }
        }
        
        return rooms
    }
}
