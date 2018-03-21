//
//  RGSharedDataManager.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

class RGSharedDataManager: NSObject {
    
    // App mode
    static var appMode: AppMode = .prod {
        didSet {
            MapViewController.resetView(for: appMode)
        }
    }
    
    // Room information
    static var selectedRoom: String?
    
    // Floor information
    static var floor: Floor! {
        didSet {
            selectedRoom = ""
            
            if floor.tiles?.count == 0 {
                createTiles(for: floor)
            }
            
            MapViewController.resetView(for: appMode)
            MapViewController.changeMap(to: floor.image)
        }
    }
    
    // Map sizes
    static var numberOfRows: Int!
    static var numberOfColumns: Int!
    
    // Bluetooth Low Energy service
    static let ble = BLEService()
    
    // Detect location on changing value of the json
    static var jsonData: Any! {
        didSet {        
            RGLocalisation.detectLocation()
        }
    }
    
    /**
     Init tiles for the floor.
     
     - parameter floor: The current floor to create tiles for.
    */
    fileprivate static func createTiles(for floor: Floor) {
        for i in 0...numberOfRows - 1 {
            for j in 0...numberOfColumns - 1 {
                // Create a new tile
                let tile = Tile(context: PersistenceService.context)
                
                // Set the location for the tile
                tile.row = Int16(i)
                tile.col = Int16(j)
                
                // Add tile to the floor
                floor.addToTiles(tile)
                
                // Save the context to CoreData
                PersistenceService.saveContext()
            }
        }
    }
    
    /**
     Init data for when the application is open for the first time
     */
    static func initData(floorLevel: Int, mapImage: NSData) {
        do {
            // Get number of floors from CoreData
            let numberOfFloors = try PersistenceService.context.count(for: NSFetchRequest(entityName: "Floor"))
            
            // If there are no floors, create the initial one
            if numberOfFloors == 0 {
                // Create a new floor
                let _ = addFloor(level: floorLevel, mapImage: mapImage)
                setFloor(level: floorLevel)
                
                // Set the app mode to dev to display log and develop app
                RGSharedDataManager.appMode = .dev
            } else {
                debugPrint("Data already created. Setting floor to default \(floorLevel).")
                setFloor(level: floorLevel)
            }
        } catch {
            debugPrint("Error in Floor Count fetchRequest")
        }
    }
}

