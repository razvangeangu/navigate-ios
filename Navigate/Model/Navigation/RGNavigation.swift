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
    static var shortestPath: [Tile]? {
        didSet {
            if shortestPath != nil && shortestPath!.count > 0 {
                MapViewController.shouldShowPath = true
                MapViewController.showCurrentPath()
            }
        }
    }
    static var destinationTile: Tile? {
        willSet {
            previousDestinationTile = destinationTile
        }
    }
    static var previousDestinationTile: Tile?
    
    override init() {
        super.init()
        
        RGNavigation.pathFinder.dataSource = self
    }
    
    func walkableAdjacentTilesForTile(tile: Tile) -> [Tile] {
        let adjacentTiles = RGSharedDataManager.getAdjacentTiles(column: Int(tile.col), row: Int(tile.row))
        return adjacentTiles.filter { $0.type != CDTileType.wall.rawValue }
    }
    
    func costToMoveFromTile(fromTile: Tile, toAdjacentTile toTile: Tile) -> Int {
        return 1
    }
    
    static func moveTo(fromTile: Tile, toTile: Tile) {
        DispatchQueue.main.async {
            var actualTile = toTile
            if toTile.type == CDTileType.wall.rawValue {
                if let accessibleTile = RGSharedDataManager.getAdjacentTiles(column: Int(actualTile.col), row: Int(actualTile.row)).first(where: { $0.type != CDTileType.wall.rawValue }) {
                    actualTile = accessibleTile
                } else {
                    MapViewController.prodLog("Cannot find path to destination.")
                }
            } else {
                RGNavigation.shortestPath = RGNavigation.pathFinder.shortestPath(fromTile: fromTile, toTile: actualTile)
            }
        }
    }
    
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
    
    private func insertStep(_ step: ShortestPathStep, inOpenSteps openSteps: inout [ShortestPathStep]) {
        openSteps.append(step)
        openSteps.sort { $0.fScore <= $1.fScore }
    }
    
    func hScoreFromTile(_ fromTile: Tile, toTile: Tile) -> Int {
        return abs(Int(toTile.col) - Int(fromTile.col)) + abs(Int(toTile.row) - Int(fromTile.row))
    }
    
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
    
    init(position: Tile) {
        self.position = position
    }
    
    func setParent(_ parent: ShortestPathStep, withMoveCost moveCost: Int) {
        self.parent = parent
        self.gScore = parent.gScore + moveCost
    }
}

private func ==(lhs: ShortestPathStep, rhs: ShortestPathStep) -> Bool {
    return lhs.position == rhs.position
}

extension ShortestPathStep: CustomStringConvertible {
    var description: String {
        return "pos=\(position) g=\(gScore) h=\(hScore) f=\(fScore)"
    }
}
