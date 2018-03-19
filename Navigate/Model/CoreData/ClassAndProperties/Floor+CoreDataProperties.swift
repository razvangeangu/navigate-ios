//
//  Floor+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension Floor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Floor> {
        return NSFetchRequest<Floor>(entityName: "Floor")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var level: Int16
    @NSManaged public var tiles: NSSet?
    @NSManaged public var rooms: NSSet?

}

// MARK: Generated accessors for tiles
extension Floor {

    @objc(addTilesObject:)
    @NSManaged public func addToTiles(_ value: Tile)

    @objc(removeTilesObject:)
    @NSManaged public func removeFromTiles(_ value: Tile)

    @objc(addTiles:)
    @NSManaged public func addToTiles(_ values: NSSet)

    @objc(removeTiles:)
    @NSManaged public func removeFromTiles(_ values: NSSet)

}

// MARK: Generated accessors for rooms
extension Floor {

    @objc(addRoomsObject:)
    @NSManaged public func addToRooms(_ value: Room)

    @objc(removeRoomsObject:)
    @NSManaged public func removeFromRooms(_ value: Room)

    @objc(addRooms:)
    @NSManaged public func addToRooms(_ values: NSSet)

    @objc(removeRooms:)
    @NSManaged public func removeFromRooms(_ values: NSSet)

}
