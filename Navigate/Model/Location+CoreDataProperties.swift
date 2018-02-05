//
//  Location+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 05/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var x: Int16
    @NSManaged public var y: Int16
    @NSManaged public var locations: NSSet?

}

// MARK: Generated accessors for locations
extension Location {

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: Tile)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: Tile)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSSet)

}
