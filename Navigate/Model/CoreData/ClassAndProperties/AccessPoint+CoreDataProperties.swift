//
//  AccessPoint+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 25/03/2018.
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
    @NSManaged public var uuid: String?
    @NSManaged public var recordID: NSData?
    @NSManaged public var recordName: String?
    @NSManaged public var lastUpdate: NSDate?
    @NSManaged public var tile: Tile?

}
