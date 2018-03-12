//
//  RGData.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreData

class RGData: NSObject {
    
    var floorLevel = 6
    var floor: Floor!
    
    let ble = BLEService()
    
    override init() {
        super.init()
    }
    
    func connect(to: String) {
        ble.connect(to: to)
    }
    
    func setFloor(level: Int) {
        floor = getFloor(level: floorLevel)
        
        if floor == nil {
            floor = Floor(context: PersistenceService.context)
            floor.level = Int16(level)
        }
    }
    
    func getFloor(level: Int) -> Floor? {
        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        do {
            let floors = try PersistenceService.context.fetch(fetchRequest)
            for floor in floors {
                if floor.level == floorLevel {
                    return floor
                }
            }
        } catch {
            print("Error in Floor fetchRequest")
        }
        
        return nil
    }
    
    func getAccessPoints() -> NSSet? {
        let jsonObject = ble.getWiFiList()
        let accessPoints = NSMutableSet()
        
        for accessPoint in jsonObject as! [[Any]] {
            let address = String.init(describing: accessPoint[0])
            let strength = Int64.init(exactly: accessPoint[1] as! NSNumber)!
            let ap = AccessPoint(context: PersistenceService.context)
            ap.uuid = address
            ap.strength = strength
            accessPoints.add(ap)
        }
        
        return accessPoints
    }
    
    func saveDataToTile(column: Int, row: Int) -> Bool {
        var saved = false
        let accessPoints = getAccessPoints()
        
        //        for tileAny in floor.tiles! {
        //            if let tile = tileAny as? Tile {
        //                if tile.x == row && tile.y == column {
        //                    for accessPoint in accessPoints! {
        //                        let accessPoint = accessPoint as! AccessPoint
        //                        if !(tile.accessPoints?.contains(where: { (savedAP) -> Bool in
        //                            let savedAP = savedAP as! AccessPoint
        //                            if savedAP.uuid == accessPoint.uuid {
        //                                return true
        //                            }
        //
        //                            return false
        //                        }))! {
        //                            tile.addToAccessPoints(accessPoint)
        //                        }
        //                    }
        //
        //                    saved = true
        //                    break
        //                }
        //                print(tile.floor as Any)
        //            }
        //        }
        
        if !saved {
            let tile = Tile(context: PersistenceService.context)
            tile.x = Int16(row)
            tile.y = Int16(column)
            tile.accessPoints = accessPoints
            tile.floor = floor
            floor.addToTiles(tile)
            
            saved = true
        }
        
        return saved
    }
    
    func accessPointHasData(column: Int, row: Int) -> Bool {
        for tile in floor.tiles! {
            let tile = tile as! Tile
            if tile.x == Int16(row) && tile.y == Int16(column) {
                return (tile.accessPoints?.count)! > 0
            }
        }
        return false
    }
}
