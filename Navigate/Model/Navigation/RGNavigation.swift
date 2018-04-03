//
//  RGNavigation.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 13/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

// https://www.raywenderlich.com/105437/implement-pathfinding-swift
class RGNavigation: NSObject, PathfinderDataSource {
    
    private static let pathFinder = AStarPathfinder()
    
    /**
     The shortest path to the selected destination that calls the view on set to display the current navigation path.
     */
    static var shortestPath: [Tile]? {
        didSet {
            
            // If a path has been found
            if shortestPath != nil && shortestPath!.count > 0 && previousDestinationTile != destinationTile {
                MapViewController.showCurrentPath()
            }
        }
    }
    
    /**
     The destination tile for the path finder. Sets the previous destination tile before setting this one.
     */
    static var destinationTile: Tile? {
        willSet {
            previousDestinationTile = destinationTile
        }
    }
    
    /**
     The previous destination tile.
     */
    static var previousDestinationTile: Tile?
    
    override init() {
        super.init()
        
        // Set the data source to self
        RGNavigation.pathFinder.dataSource = self
    }
    
    /**
     Return the adjacent tiles based on their type.
     If the tile is not of type wall and is one space away
     then it gets added to the sequence.
     
     - parameter tile: A **Tile** object for which the adjacent tiles should be calculated.
     
     - Returns: A sequence of **Tile** that represents the adjancet tiles horizontally and vertically 1 space away that are not of type wall.
     */
    func walkableAdjacentTilesForTile(tile: Tile) -> [Tile] {
        
        // Get the adjacent tiles for the specific type
        let adjacentTiles = RGSharedDataManager.getAdjacentTiles(column: Int(tile.col), row: Int(tile.row))
        
        // Filter the adjacent tiles based on the type
        return adjacentTiles.filter { $0.type != CDTileType.wall.rawValue }
    }
    
    /**
     The cost to move from one tile to another.
     
     - parameter fromTile: A **Tile** object from which the cost should be calculated.
     - parameter toAdjacentTile toTile: A **Tile** object to which the cost should be calculated.
     
     - Returns: An **Int** that represents the cost of moving towards the tile.
     */
    func costToMoveFromTile(fromTile: Tile, toAdjacentTile toTile: Tile) -> Int {
        return 1
    }
    
    /**
     A function that moves the current path finder to the next tile.
     
     - parameter fromTile: A **Tile** object from which the path should be calculated.
     - parameter toTile: A **Tile** object to which the path should be calculated.
     */
    static func moveTo(fromTile: Tile, toTile: Tile) {
        
        // Async
        DispatchQueue.main.async {
            
            // Init the actual tile
            var actualTile = toTile
            
            // If the tile is of type Wall
            if toTile.type == CDTileType.wall.rawValue {
                
                // Find the accessible tile in the adjacent tiles of the tapped tile.
                if let accessibleTile = RGSharedDataManager.getAdjacentTiles(column: Int(actualTile.col), row: Int(actualTile.row)).first(where: { $0.type != CDTileType.wall.rawValue }) {
                    
                    // Set the actual tile
                    actualTile = accessibleTile
                } else {
                    MapViewController.prodLog("Cannot find path to destination.")
                }
            } else {
                
                // Find the shortest path
                RGNavigation.shortestPath = RGNavigation.pathFinder.shortestPath(fromTile: fromTile, toTile: actualTile)
            }
        }
    }
    
    /**
     A function that calculates the shortest path from a tile to another tile.
     
     - parameter fromTile: A **Tile** object that represents the start of the path.
     - parameter toTile: A **Tile** object that represents the end of the path.
     
     - Returns: A seqeuence of **Tile** objects that represent the path from *fromTile* to *toTile*.
     */
    static func getShortestPath(fromTile: Tile, toTile: Tile) -> [Tile]? {
        return RGNavigation.pathFinder.shortestPath(fromTile: fromTile, toTile: toTile)
    }
}

protocol PathfinderDataSource: NSObjectProtocol {
    func walkableAdjacentTilesForTile(tile: Tile) -> [Tile]
    func costToMoveFromTile(fromTile: Tile, toAdjacentTile toTile: Tile) -> Int
}

class AStarPathfinder {
    weak var dataSource: PathfinderDataSource?
    
    /**
     A function to insert a step in the open steps sequence. The function then sorts based on the score.
     
     - parameter step: The step to be inserted.
     - parameter inOpenSteps openSteps: The sequence where the step should be inserted.
     */
    private func insertStep(_ step: ShortestPathStep, inOpenSteps openSteps: inout [ShortestPathStep]) {
        openSteps.append(step)
        openSteps.sort { $0.fScore <= $1.fScore }
    }
    
    /**
     A function to calculate the cost of movement from a **Tile** to another **Tile**.
     
     - parameter fromTile: A **Tile** object that represents the start of the path.
     - parameter toTile: A **Tile** object that represents the end of the path.
     */
    func hScoreFromTile(_ fromTile: Tile, toTile: Tile) -> Int {
        return abs(Int(toTile.col) - Int(fromTile.col)) + abs(Int(toTile.row) - Int(fromTile.row))
    }
    
    /**
     The core A* algorithm
     
     - parameter fromTile: A **Tile** object that represents the start of the path.
     - parameter toTile: A **Tile** object that represents the end of the path.
     
     - Returns: A seqeuence of **Tile** objects that represent the path from *fromTile* to *toTile*.
     */
    func shortestPath(fromTile: Tile, toTile: Tile) -> [Tile]? {
        // 1
        if self.dataSource == nil {
            return nil
        }
        let dataSource = self.dataSource!
        
        // 2
        var closedSteps = Set<ShortestPathStep>()
        var openSteps = [ShortestPathStep(position: fromTile)]
        
        while !openSteps.isEmpty {
            // 3
            let currentStep = openSteps.remove(at: 0)
            closedSteps.insert(currentStep)
            
            // 4
            if currentStep.position == toTile {
                var allSteps = [Tile]()
                var step: ShortestPathStep? = currentStep
                while step != nil {
                    allSteps.append(step!.position)
                    step = step!.parent
                }
                return allSteps
            }
            
            // 5
            let adjacentTiles = dataSource.walkableAdjacentTilesForTile(tile: currentStep.position)
            for tile in adjacentTiles {
                // 6
                let step = ShortestPathStep(position: tile)
                if closedSteps.contains(step) {
                    continue
                }
                let moveCost = dataSource.costToMoveFromTile(fromTile: currentStep.position, toAdjacentTile: step.position)
                
                if let existingIndex = openSteps.index(of: step) {
                    // 7
                    let step = openSteps[existingIndex]
                    
                    if currentStep.gScore + moveCost < step.gScore {
                        step.setParent(currentStep, withMoveCost: moveCost)
                        
                        openSteps.remove(at: existingIndex)
                        insertStep(step, inOpenSteps: &openSteps)
                    }
                    
                } else {
                    // 8
                    step.setParent(currentStep, withMoveCost: moveCost)
                    step.hScore = hScoreFromTile(step.position, toTile: toTile)
                    
                    insertStep(step, inOpenSteps: &openSteps)
                }
            }
            
        }
        
        return nil
    }
}

private class ShortestPathStep: Hashable {
    let position: Tile
    var parent: ShortestPathStep?
    
    var gScore = 0
    var hScore = 0
    var fScore: Int {
        return gScore + hScore
    }
    
    var hashValue: Int {
        return position.col.hashValue + position.row.hashValue
    }
    
    /**
     An initialiser for the step with a Tile position.
     
     - parameter position: A **Tile** object represented as the position of this step
     */
    init(position: Tile) {
        self.position = position
    }
    
    /**
     A function to set the parent of this step.
     
     - parameter parent: The parent step of this object.
     - parameter withMoveCost moveCost: An **Int** that represents the cost of movement.
     */
    func setParent(_ parent: ShortestPathStep, withMoveCost moveCost: Int) {
        self.parent = parent
        self.gScore = parent.gScore + moveCost
    }
}

/**
 Overloading the equals method for ShortestPathStep that checks the position equality.
 
 - parameter lhs: The left side **ShortestPathStep** object.
 - parameter rhs: The right side **ShortestPathStep** object.
 
 - Returns: The equality statement.
 */
private func ==(lhs: ShortestPathStep, rhs: ShortestPathStep) -> Bool {
    return lhs.position == rhs.position
}

extension ShortestPathStep: CustomStringConvertible {
    var description: String {
        return "pos=\(position) g=\(gScore) h=\(hScore) f=\(fScore)"
    }
}
