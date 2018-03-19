//
//  RGSharedDataManagerTilesExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

extension RGSharedDataManager {
    /**
     Saves the data for the tile at the specified location.
     
     - parameter column: The column of the tile *(y index of the tile in database)*
     - parameter row: The row of the tile *(x index of the tile in database)*
     
     - Returns: **true** if the data has been saved successfuly or **false** if could not find APs.
     */
    static func saveDataToTile(column: Int, row: Int) -> Bool {
        guard let accessPoints = getAccessPoints() else { return false }
        
        guard let tile = getTile(col: column, row: row) else { return false }
        
        // Add the room to the tile
        if let tileRoom = getRoom(name: selectedRoom!) {
            tile.room = tileRoom
        } else {
            // Create new room
            let room = Room(context: PersistenceService.context)
            
            // Set the room name
            room.name = selectedRoom
            
            // Add tiles to the room
            room.addToTiles(tile)
            
            // Set the room for this tile
            tile.room = room
        }
        
        // Add the APs data
        tile.accessPoints = accessPoints
        
        // Add tile to APs
        for accessPoint in accessPoints {
            (accessPoint as! AccessPoint).addToTiles(tile)
        }
        
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
    static func tileHasData(column: Int, row: Int) -> Bool {
        // Get all the tiles
        for tile in RGSharedDataManager.floor.tiles! {
            
            // If the tile matches
            if (tile as! Tile).row == row && (tile as! Tile).col == column {
                // Check the number of APs
                return ((tile as! Tile).accessPoints?.count)! > 0
            }
        }
        return false
    }
    
    /**
     Get a tile at a specific location from the current floor.
     
     - Returns: A **Tile** object from the CoreData.
     */
    fileprivate static func getTile(col: Int, row: Int) -> Tile? {
        for tile in RGSharedDataManager.floor.tiles! {
            let tile = tile as! Tile
            if tile.row == row && tile.col == col {
                return tile
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
        
        for tile in RGSharedDataManager.floor.tiles! {
            let tile = tile as! Tile
            
            // up
            if tile.row == row - 1 && tile.col == column {
                adjacentTiles.append(tile)
                continue
            }
            
            // right
            if tile.row == row && tile.col == column + 1 {
                adjacentTiles.append(tile)
                continue
            }
            
            // down
            if tile.row == row + 1 && tile.col == column {
                adjacentTiles.append(tile)
                continue
            }
            
            // left
            if tile.row == row && tile.col == column - 1 {
                adjacentTiles.append(tile)
                continue
            }
        }
        
        return adjacentTiles
    }
}
