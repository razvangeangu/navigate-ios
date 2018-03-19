//
//  Tile+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension Tile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tile> {
        return NSFetchRequest<Tile>(entityName: "Tile")
    }

    @NSManaged public var col: Int16
    @NSManaged public var row: Int16
    @NSManaged public var type: String?
    @NSManaged public var accessPoints: NSSet?
    @NSManaged public var floor: Floor?
    @NSManaged public var room: Room?

}

// MARK: Generated accessors for accessPoints
extension Tile {

    @objc(addAccessPointsObject:)
    @NSManaged public func addToAccessPoints(_ value: AccessPoint)

    @objc(removeAccessPointsObject:)
    @NSManaged public func removeFromAccessPoints(_ value: AccessPoint)

    @objc(addAccessPoints:)
    @NSManaged public func addToAccessPoints(_ values: NSSet)

    @objc(removeAccessPoints:)
    @NSManaged public func removeFromAccessPoints(_ values: NSSet)

}
