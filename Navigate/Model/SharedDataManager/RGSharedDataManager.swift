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
    static var selectedRoom: String?
    static var mapImage: NSData!
    
    // Floor information
    static var floorLevel: Int!
    static var floor: Floor! {
        didSet {
            floorLevel = Int(floor.level)
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
    
    static func initData() {
        do {
            let numberOfFloors = try PersistenceService.context.count(for: NSFetchRequest(entityName: "Floor"))
            if numberOfFloors == 0 {
                
                // Create a new floor
                addFloor(level: floorLevel, mapImage: mapImage)
                floor = getFloor(level: floorLevel)
                
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
            } else {
                debugPrint("Data already created")
            }
        } catch {
            debugPrint("Error in Floor Count fetchRequest")
        }
    }
}

