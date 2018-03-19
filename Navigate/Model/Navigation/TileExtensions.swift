//
//  TileExtensions.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 18/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

extension Tile: PathfinderDataSource {
    func walkableAdjacentTilesForTile(tile: Tile) -> [Tile] {
        let adjacentTiles = RGSharedDataManager.getAdjacentTiles(column: Int(tile.y), row: Int(tile.x))
        return adjacentTiles.filter { _ in true }
    }
    
    func costToMoveFromTile(fromTile: Tile, toAdjacentTile toTile: Tile) -> Int {
        return 1
    }
    
}
