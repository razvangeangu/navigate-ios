//
//  AccessPoint+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 05/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension AccessPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccessPoint> {
        return NSFetchRequest<AccessPoint>(entityName: "AccessPoint")
    }

    @NSManaged public var strength: Int64
    @NSManaged public var uuid: UUID?
    @NSManaged public var tiles: NSSet?

}

// MARK: Generated accessors for tiles
extension AccessPoint {

    @objc(addTilesObject:)
    @NSManaged public func addToTiles(_ value: Tile)

    @objc(removeTilesObject:)
    @NSManaged public func removeFromTiles(_ value: Tile)

    @objc(addTiles:)
    @NSManaged public func addToTiles(_ values: NSSet)

    @objc(removeTiles:)
    @NSManaged public func removeFromTiles(_ values: NSSet)

}
