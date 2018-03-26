//
//  Room+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension Room {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Room> {
        return NSFetchRequest<Room>(entityName: "Room")
    }

    @NSManaged public var name: String?
    @NSManaged public var recordID: NSData?
    @NSManaged public var recordName: String?
    @NSManaged public var lastUpdate: NSDate?
    @NSManaged public var floor: Floor?
    @NSManaged public var tiles: NSSet?

}

// MARK: Generated accessors for tiles
extension Room {

    @objc(addTilesObject:)
    @NSManaged public func addToTiles(_ value: Tile)

    @objc(removeTilesObject:)
    @NSManaged public func removeFromTiles(_ value: Tile)

    @objc(addTiles:)
    @NSManaged public func addToTiles(_ values: NSSet)

    @objc(removeTiles:)
    @NSManaged public func removeFromTiles(_ values: NSSet)

}
