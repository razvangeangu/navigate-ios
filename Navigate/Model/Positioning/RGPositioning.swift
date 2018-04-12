//
//  RGPositioning.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 13/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

class RGPositioning: NSObject {
    
    // Current location of the iOS device
    static var previousLocation = (-1, -1)
    static var currentLocation = (-1, -1) {
        willSet {
            // Save the current location for future references
            self.previousLocation = self.currentLocation
        }
        didSet {
            DispatchQueue.main.async {
                // If the current location is valid (not the initial value and in the bounds)
                if currentLocation != (-1, -1) {
                    
                    // Show debugging log
                    // MapViewController.devLog(data: "Found Location: \(currentLocation)")
                    
                    // Show the current location
                    MapViewController.showCurrentLocation(currentLocation)
                    
                    // Show the current path
                    if let destination = RGNavigation.destinationTile {
                        MapViewController.shouldShowPath = true
                        MapViewController.showPath(to: destination)
                    }
                } else {
                    MapViewController.removeLocationNode()
                }
            }
        }
    }
    
    static var heading: Float?
    
    /**
     A function that detects the location of the iOS device
     by checking the strength of the APs around the device
     and the one saved in the database.
     
     - parameter floor: The floor to scan the location for.
     */
    static func detectLocation(floor: Floor, completion: (((Int, Int), [[Int]]) -> Void)?) {
        guard let currentAccessPoints = RGSharedDataManager.getAccessPoints() else {
            currentLocation = (-1, -1)
            return
        }
        
        // Background queue
        DispatchQueue.global(qos: .userInteractive).async {
            // A 2D array that holds the data of the APs
            var matrix = [[Int]](repeating: [Int](repeating: 0, count: RGSharedDataManager.numberOfColumns), count: RGSharedDataManager.numberOfRows)
                
            if let tiles = floor.tiles {
            
                // Loop through all the tiles
                for case let tile as Tile in tiles {
                    
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
                
                var currentLocation = (-1, -1)
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
                
                completion?(currentLocation, matrix)
            }
        }
    }
    
    /**
     A function that detects the floor level by comparing the number of access points identified on each floor.
     
     - parameter completion: Returns an **Int** number representing the floor level.
     */
    static func getFloorLevel(completion: ((_ level: Int?) -> Void)?) {
        
        // Create the level variable
        var level: Int?
        var maxNumberOfAPs = Int.min
        
        // Get all the floors
        guard let floors = RGSharedDataManager.getFloors() else { return }
        
        // For each floor found
        for i in 0..<floors.count {
            
            // Detect the location
            detectLocation(floor: floors[i]) { (location, matrix) in
                
                // Check the maximum number of identified Access Points
                if matrix[location.0][location.1] > maxNumberOfAPs {
                    maxNumberOfAPs = matrix[location.0][location.1]
                    level = Int(floors[i].level)
                }
                
                // If checked all the levels
                if floors[i].level == floors.last!.level {
                    
                    // Call optional completion with the found level
                    completion?(level)
                }
            }
        }
    }
}
