//
//  RGLocalisation.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 13/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

class RGLocalisation: NSObject {
    
    // Current location of the iOS device
    static var currentLocation = (-1, -1)
    
    /**
     A function that detects the location of the iOS device
     by checking the strength of the APs around the device
     and the one saved in the database.
     */
    static func detectLocation() {
        let currentAccessPoints = RGSharedDataManager.getAccessPoints()!
        
        // A 2D array that holds the data of the APs
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: RGSharedDataManager.numberOfColumns), count: RGSharedDataManager.numberOfRows)
        
        // Loop through all the tiles
        for case let tile as Tile in RGSharedDataManager.floor.tiles! {
            
            // Loop through all the APs from the each tile
            for case let accessPoint as AccessPoint in tile.accessPoints! {
                
                // Loop thorugh all the APs from the current scan
                for case let currentAccessPoint as AccessPoint in currentAccessPoints {
                    
                    // Compare their unique id
                    if accessPoint.uuid == currentAccessPoint.uuid {
                        
                        // Compare their strength
                        if accessPoint.strength > currentAccessPoint.strength - 10 {
                            if accessPoint.strength < currentAccessPoint.strength + 10 {
                                
                                // Increase the similarity value of the AP / Tile
                                matrix[Int(tile.x)][Int(tile.y)] += 1
                            }
                        }
                    }
                }
            }
        }
        
        // Current location local value to find the maximum in the matrix
        var currentLocation = self.currentLocation
        var max = -1
        
        // Loop through all the tiles
        for i in 0...RGSharedDataManager.numberOfRows - 1 {
            for j in 0...RGSharedDataManager.numberOfColumns - 1 {
                
                // Find maximum and save it
                if matrix[i][j] > max {
                    currentLocation = (i, j)
                    max = matrix[i][j]
                }
            }
        }
        
        // If the current location is valid (not the initial value and in the bounds)
        if currentLocation != (-1, -1) {
            
            // Show debugging log
            MapViewController.devLog(data: "Found: \(currentLocation)")
            
            // Reset the map
            MapViewController.activateTiles()
            
            // Show the current location
            MapViewController.setTileColor(column: currentLocation.1, row: currentLocation.0, color: .purple)
            
            // Save the current location
            self.currentLocation = currentLocation
        }
    }
}
