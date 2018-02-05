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

    @NSManaged public var accessPoints: AccessPoint?
    @NSManaged public var location: Location?
    @NSManaged public var accessPointsList: NSSet?
    @NSManaged public var locationRelation: Location?
    @NSManaged public var newRelationship: Floor?

}

// MARK: Generated accessors for accessPointsList
extension Tile {

    @objc(addAccessPointsListObject:)
    @NSManaged public func addToAccessPointsList(_ value: AccessPoint)

    @objc(removeAccessPointsListObject:)
    @NSManaged public func removeFromAccessPointsList(_ value: AccessPoint)

    @objc(addAccessPointsList:)
    @NSManaged public func addToAccessPointsList(_ values: NSSet)

    @objc(removeAccessPointsList:)
    @NSManaged public func removeFromAccessPointsList(_ values: NSSet)

}
