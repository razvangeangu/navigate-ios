//
//  Tile+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 05/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension Tile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Tile> {
        return NSFetchRequest<Tile>(entityName: "Tile")
    }

    @NSManaged public var x: Int16
    @NSManaged public var y: Int16
    @NSManaged public var floor: Floor?
    @NSManaged public var accessPoints: NSSet?

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
