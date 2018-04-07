//
//  RGSharedDataManager.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

class RGSharedDataManager: NSObject {
    
    // App mode
    static var appMode: AppMode = .prod {
        didSet {
            MapViewController.resetView(for: appMode)
        }
    }
    
    // Room information
    static var selectedRoom: String? {
        didSet {
            if RGSharedDataManager.appMode == .prod {
                guard let selectedRoomObject = RGSharedDataManager.getRoom(name: selectedRoom!, floor: RGSharedDataManager.floor) else { return }
                guard let doors = RGSharedDataManager.getDoors(for: selectedRoomObject) else { return }
                guard let fromTile = RGSharedDataManager.getTile(col: RGPositioning.currentLocation.1, row: RGPositioning.currentLocation.0) else { return }
                
                var maxCount = Int.max
                var closestDoor: Tile?
                for door in doors {
                    if let shortestPath = RGNavigation.getShortestPath(fromTile: fromTile, toTile: door) {
                        if shortestPath.count < maxCount {
                            maxCount = shortestPath.count
                            closestDoor = door
                        }
                    }
                }
                
                if let door = closestDoor {
                    RGNavigation.destinationTile = door
                }
            }
        }
    }
    
    // Floor information
    static var floor: Floor! {
        didSet {
            DispatchQueue.main.async {
                
                // UIChanges on the main thread
                selectedRoom = ""
                MapViewController.changeMap(to: floor.image)
                MapViewController.reloadData()
            }
        }
    }
    
    // Map sizes
    static var numberOfRows: Int!
    static var numberOfColumns: Int!
    
    // Bluetooth Low Energy service
    static let ble = BLEService()
    
    // Detect location on changing value of the json
    static var jsonData: Any! {
        didSet {
            if ProgressView.didFinishLoading {
                RGPositioning.detectLocation(floor: RGSharedDataManager.floor, completion: nil)
            }
        }
    }
    
    // The tile size in meters
    static var tileLength: Float = 1.5
    
    // The selected tileType
    static var tileType: CDTileType?
    
    /**
     Init data for when the application is open for the first time.
     
     - parameter floorLevel: The level of the floor.
     - parameter mapImage: The image of the map for the floor level.
     */
    static func initData(floorLevel: Int, mapImage: NSData) {
        // Begin background task to fetch the data even if app exits
        let task = beginBackgroundTask()
        
        do {
            // Get number of floors from CoreData
            let numberOfFloors = try PersistenceService.viewContext.count(for: NSFetchRequest(entityName: "Floor"))
            
            // If there are no floors, create the initial one
            if numberOfFloors == 0 {
                CloudKitManager.fetchDataFromTheCloud {
                    if let floors = getFloors(), floors.count > 0 {
                        MapViewController.progressView.setProgress(to: 1.0)
                        
                        MapViewController.devLog(data: "Data fetched from the cloud. Setting floor to default \(floorLevel).")
                        setFloor(level: floorLevel)
                        
                        // Update UI
                        MapViewController.resetView(for: RGSharedDataManager.appMode)
                        
                        endBackgroundTask(taskID: task)
                    } else if isReachable() {
                        MapViewController.progressView.setProgress(to: 1.0)
                        
                        // Set the app mode to dev to display log and develop app
                        RGSharedDataManager.appMode = .dev
                        
                        // Create a new floor
                        let _ = addFloor(level: floorLevel, mapImage: mapImage)
                        setFloor(level: floorLevel)
                        
                        // Update UI
                        MapViewController.resetView(for: RGSharedDataManager.appMode)
                        
                        endBackgroundTask(taskID: task)
                    } else {
                        MapViewController.progressView.setProgress(to: 0)
                    }
                }
            } else {
                MapViewController.progressView.setProgress(to: 1.0)
                
                MapViewController.devLog(data: "Data already created. Setting floor to default \(floorLevel).")
                setFloor(level: floorLevel)
                
                // Update UI
                MapViewController.resetView(for: RGSharedDataManager.appMode)
                
                endBackgroundTask(taskID: task)
            }
        } catch {
            MapViewController.devLog(data: "Error in Floor Count fetchRequest")
        }
    }
    
    /**
     Write a command to the terminal of the external device.
     
     - parameter command: A string that represents the command to be executed by the external device.
     */
    static func writeToTerminal(command: String) {
        ble.write(command: command)
    }
    
    /**
     Connect to an external device using a UUID.
     
     - parameter to: UUID as string.
     */
    static func connect(to: String) {
        ble.connect(to: to)
    }
    
    /**
     Shutdown external device.
     */
    static func disconnect() {
        RGSharedDataManager.ble.stopPi()
    }
}
