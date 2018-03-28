//
//  RGSharedDataManagerTilesExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

extension RGSharedDataManager {
    /**
     Saves the data for the tile at the specified location.
     
     - parameter column: The column of the tile *(y index of the tile in database)*
     - parameter row: The row of the tile *(x index of the tile in database)*
     
     - Returns: **true** if the data has been saved successfuly or **false** if could not find APs.
     */
    static func saveDataToTile(column: Int, row: Int) -> Bool {
        
        // Get the tile from CoreData
        guard let tile = getTile(col: column, row: row) else { return false }
        
        guard let tileType = tileType else {
            MapViewController.devLog(data: "A tile type must be selected.")
            return false
        }
        
        // If the tile needs to be overwritten
        if tileType == .sample {
            resetTile(column: column, row: row)
        }
        
        // Get the APs from the BLE service
        guard let accessPoints = getAccessPoints() else { return false }
        
        // Add the room to the tile
        if let tileRoom = getRoom(name: selectedRoom!, floor: self.floor) {
            
            // Create APs in this context and add relationship to tile
            for accessPoint in accessPoints {
                let _ = createAccessPoint(address: accessPoint.uuid!, strength: accessPoint.strength, tile: tile)
            }
            
            // Set the room for this tile
            tileRoom.addToTiles(tile)
            tileRoom.lastUpdate = NSDate()
            
            // Set the type of the tile
            tile.type = tileType.rawValue
            
            // Set the last update time
            tile.lastUpdate = NSDate()
            
            // Save the context for CoreData
            PersistenceService.saveViewContext()
            
            return true
        } else {
            MapViewController.devLog(data: "A room must be selected.")
        }
        
        return false
    }
    
    /**
     Checks if the tile on the current floor has APs stored and more than 0.
     
     - parameter column: The column of the tile *(y index of the tile in database)*
     - parameter row: The row of the tile *(x index of the tile in database)*
     
     - Returns: **true** data has been found or **false** if could not find APs
     */
    static func tileHasData(column: Int, row: Int) -> Bool {
        // Get all the tiles
        for case let tile as Tile in floor.tiles! {
            // If the tile matches
            if tile.row == row && tile.col == column {
                // Check the number of APs
                return (tile.accessPoints?.count)! > 0
            }
        }
        return false
    }
    
    /**
     Get a tile at a specific location from the current floor.
     
     - Returns: A **Tile** object from the CoreData.
     */
    static func getTile(col: Int, row: Int) -> Tile? {
        if let floor = floor {
            if let tiles = floor.tiles {
                // Get all the tiles
                for case let tile as Tile in tiles {
                    // If the tile mathces
                    if tile.row == row && tile.col == col {
                        // Return the tile
                        return tile
                    }
                }
            }
        }
        
        return nil
    }
    
    /**
     Get adjacent tiles for a specific location from the current floor.
     
     - Returns: An array of tiles from the CoreData.
     */
    static func getAdjacentTiles(column: Int, row: Int) -> [Tile] {
        var adjacentTiles = [Tile]()
        
        // Get all the tiles
        for case let tile as Tile in floor.tiles! {
            // Up
            if tile.row == row - 1 && tile.col == column {
                adjacentTiles.append(tile)
                continue
            }
            
            // Right
            if tile.row == row && tile.col == column + 1 {
                adjacentTiles.append(tile)
                continue
            }
            
            // Down
            if tile.row == row + 1 && tile.col == column {
                adjacentTiles.append(tile)
                continue
            }
            
            // Left
            if tile.row == row && tile.col == column - 1 {
                adjacentTiles.append(tile)
                continue
            }
        }
        
        return adjacentTiles
    }
    
    static func resetTile(column: Int, row: Int) {
        
        // Remove tile from Core Data
        guard let tileToRemove = getTile(col: column, row: row) else { return }
        PersistenceService.viewContext.delete(tileToRemove)
        
        // Create a new tile
        let tile = Tile(context: PersistenceService.viewContext)
        tile.prepareForCloudKit()
        tile.row = Int16(row)
        tile.col = Int16(column)
        tile.type = CDTileType.sample.rawValue
        tile.lastUpdate = NSDate()
        
        floor.addToTiles(tile)
        
        // Save the context to CoreData
        PersistenceService.saveViewContext()
    }
    
    /**
     Init tiles for the floor.
     
     - parameter floor: The current floor to create tiles for.
     */
    static func createTiles(for floor: Floor) {
        if addRoom(name: "SAMPLE") {
            guard let room = getRoom(name: "SAMPLE", floor: floor) else { return }
            
            for i in 0...numberOfRows - 1 {
                for j in 0...numberOfColumns - 1 {
                    // Create a new tile
                    let tile = Tile(context: PersistenceService.viewContext)
                    tile.prepareForCloudKit()
                    
                    // Set the location for the tile
                    tile.row = Int16(i)
                    tile.col = Int16(j)
                    
                    if floor.level == Int16(6) && RGSharedDataManager.appMode == .dev {
                        tile.type = MapViewController.getTileType(column: j, row: i).rawValue
                    } else {
                        tile.type = CDTileType.sample.rawValue
                    }
                    
                    tile.lastUpdate = NSDate()
                    
                    // Add room to tile
                    room.addToTiles(tile)
                    
                    // Add floor to the tile
                    floor.addToTiles(tile)
                }
            }
        }
        
        PersistenceService.saveViewContext()
    }
}
