//
//  Floor+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension Floor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Floor> {
        return NSFetchRequest<Floor>(entityName: "Floor")
    }

    @NSManaged public var level: Int16
    @NSManaged public var tiles: NSSet?

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
