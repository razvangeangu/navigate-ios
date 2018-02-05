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
    @NSManaged public var accessPoints: NSSet?

}

// MARK: Generated accessors for accessPoints
extension AccessPoint {

    @objc(addAccessPointsObject:)
    @NSManaged public func addToAccessPoints(_ value: Tile)

    @objc(removeAccessPointsObject:)
    @NSManaged public func removeFromAccessPoints(_ value: Tile)

    @objc(addAccessPoints:)
    @NSManaged public func addToAccessPoints(_ values: NSSet)

    @objc(removeAccessPoints:)
    @NSManaged public func removeFromAccessPoints(_ values: NSSet)

}
