//
//  RGLocalisation.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 13/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

class RGLocalisation: NSObject {
    
    static var currentLocation = (0, 0)
    
    static func detectLocation() {
        let currentAccessPoints = RGSharedDataManager.getAccessPoints()!
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: RGSharedDataManager.numberOfColumns), count: RGSharedDataManager.numberOfRows)
        for case let tile as Tile in RGSharedDataManager.floor.tiles! {
            for case let accessPoint as AccessPoint in tile.accessPoints! {
                for case let currentAccessPoint as AccessPoint in currentAccessPoints {
                    if accessPoint.uuid == currentAccessPoint.uuid {
                        if accessPoint.strength > currentAccessPoint.strength - 10 {
                            if accessPoint.strength < currentAccessPoint.strength + 10 {
                                matrix[Int(tile.x)][Int(tile.y)] += 1
                            }
                        }
                    }
                }
            }
        }
        
        var currentLocation = (0, 0)
        var max = -1
        for i in 0...RGSharedDataManager.numberOfRows - 1 {
            for j in 0...RGSharedDataManager.numberOfColumns - 1 {
                if matrix[i][j] > max {
                    currentLocation = (i, j)
                    max = matrix[i][j]
                }
            }
        }
        
        ViewController.devLog(data: "Found: \(currentLocation)")
        ViewController.activateTiles()
        ViewController.setTileColor(column: currentLocation.1, row: currentLocation.0, color: .purple)
        
        self.currentLocation = currentLocation
    }
}
