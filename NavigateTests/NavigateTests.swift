//
//  NavigateTests.swift
//  NavigateTests
//
//  Created by Răzvan-Gabriel Geangu on 05/11/2017.
//  Copyright © 2017 Răzvan-Gabriel Geangu. All rights reserved.
//

import XCTest
@testable import Navigate

class NavigateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        // Create floor entity
        let floor = Floor(entity: Floor.entity(), insertInto: nil)
        floor.level = 1
        RGSharedDataManager.floor = floor
        
        // Create room entity
        let room = Room(entity: Room.entity(), insertInto: nil)
        room.name = "SAMPLE"
        room.floor = floor
        
        // Set the bounds
        RGSharedDataManager.numberOfColumns = 9
        RGSharedDataManager.numberOfRows = 9
        
        // Set the data for jsonData
        var currentData = [[Any]]()
        
        // Create tile entities
        for i in 0..<RGSharedDataManager.numberOfRows {
            for j in 0..<RGSharedDataManager.numberOfColumns {
                let tile = Tile(entity: Tile.entity(), insertInto: nil)
                tile.row = Int16(i)
                tile.col = Int16(j)
                tile.type = CDTileType.sample.rawValue
                room.addToTiles(tile)
                floor.addToTiles(tile)
                
                // Create access points
                for i in 0..<20 {
                    let accessPoint = AccessPoint(entity: AccessPoint.entity(), insertInto: nil)
                    accessPoint.uuid = "\(i)"
                    accessPoint.strength = Int64(randomNumber(inRange: -50...50))
                    
                    if i == 0 && j == 0 {
                        accessPoint.uuid = "\(i + 19)"
                        accessPoint.strength = Int64(randomNumber(inRange: 60...70))
                        
                        currentData.append([accessPoint.uuid!, accessPoint.strength])
                    }
                    
                    tile.addToAccessPoints(accessPoint)
                }
            }
        }
        
        // Necessary to test the positioning and navigation
        RGSharedDataManager.jsonData = currentData
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPositioning() {
        let tileForCurrentLocation = RGSharedDataManager.getTile(col: 0, row: 0)
        
        RGPositioning.detectLocation(floor: RGSharedDataManager.floor) { (currentLocation, _) in
            XCTAssertEqual(currentLocation.0, Int(tileForCurrentLocation!.row))
            XCTAssertEqual(currentLocation.1, Int(tileForCurrentLocation!.col))
        }
    }
    
    func testNavigation() {
        guard let tileForCurrentLocation = RGSharedDataManager.getTile(col: 0, row: 0) else { fatalError() }
        guard let tileForDestination = RGSharedDataManager.getTile(col: 8, row: 8) else { fatalError() }
        
        let shortestPath = RGNavigation.getShortestPath(fromTile: tileForCurrentLocation, toTile: tileForDestination)
        let currentLocation = shortestPath?.last!
        let destination = shortestPath?.first!
        
        XCTAssertEqual(tileForCurrentLocation, currentLocation)
        XCTAssertEqual(destination, tileForDestination)
    }
    
    // Credits: https://stackoverflow.com/questions/24132399/how-does-one-make-random-number-between-range-for-arc4random-uniform
    public func randomNumber<T : SignedInteger>(inRange range: ClosedRange<T> = 1...6) -> T {
        let length = Int64(range.upperBound - range.lowerBound + 1)
        let value = Int64(arc4random()) % length + Int64(range.lowerBound)
        return T(value)
    }
}
