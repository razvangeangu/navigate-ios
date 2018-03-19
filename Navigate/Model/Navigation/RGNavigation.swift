//
//  RGNavigation.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 13/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

class RGNavigation: NSObject {
    
}

protocol PathfinderDataSource: NSObjectProtocol {
    func walkableAdjacentTilesForTile(tile: Tile) -> [Tile]
    func costToMoveFromTile(fromTile: Tile, toAdjacentTile toTile: Tile) -> Int
}

/** A pathfinder based on the A* algorithm to find the shortest path between two locations */
class AStarPathfinder {
    weak var dataSource: PathfinderDataSource?
    
    func shortestPathFromTileCoord(fromTile: Tile, toTile: Tile) -> [Tile]? {
        // placeholder: move immediately to the destination coordinate
        return [toTile]
    }
}
