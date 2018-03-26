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
    static var previousLocation = (-1, -1)
    static var currentLocation = (-1, -1) {
        didSet {
            DispatchQueue.main.async {
                // If the current location is valid (not the initial value and in the bounds)
                if currentLocation != (-1, -1) {
                    
                    // Show debugging log
                    MapViewController.devLog(data: "Found Location: \(currentLocation)")
                    
                    // Save the current location for future references
                    self.previousLocation = self.currentLocation
                    
                    // Show the current location
                    MapViewController.showCurrentLocation(currentLocation)
                    
                    // Show the current path
                    if let destination = RGNavigation.destinationTile {
                        MapViewController.shouldShowPath = true
                        MapViewController.showPath(to: destination)
                    }
                } else {
                    MapViewController.removeLocationNode()
                    MapViewController.devLog(data: "Location not found..")
                }
            }
        }
    }
    
    static var heading: Float?
    
    /**
     A function that detects the location of the iOS device
     by checking the strength of the APs around the device
     and the one saved in the database.
     */
    static func detectLocation() {
        guard let currentAccessPoints = RGSharedDataManager.getAccessPoints() else {
            currentLocation = (-1, -1)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            // A 2D array that holds the data of the APs
            var matrix = [[Int]](repeating: [Int](repeating: 0, count: RGSharedDataManager.numberOfColumns), count: RGSharedDataManager.numberOfRows)
            
            // Loop through all the tiles
            for case let tile as Tile in RGSharedDataManager.floor.tiles! {
                
                // If tile contains APs
                if let accessPoints = tile.accessPoints {
                    
                    // Loop through all the APs from the each tile
                    for case let accessPoint as AccessPoint in accessPoints {
                        
                        // Loop thorugh all the APs from the current scan
                        for currentAccessPoint in currentAccessPoints {
                            
                            // Compare their unique id
                            if accessPoint.uuid == currentAccessPoint.uuid {
                                
                                // Compare their strength
                                if accessPoint.strength > currentAccessPoint.strength - 5 {
                                    if accessPoint.strength < currentAccessPoint.strength + 5 {
                                        
                                        // Increase the similarity value of the AP / Tile
                                        matrix[Int(tile.row)][Int(tile.col)] += 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // Current location local value to find the maximum in the matrix
            var currentLocation = self.currentLocation
            var max = 0
            
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
            
            self.currentLocation = currentLocation
        }
    }
}
