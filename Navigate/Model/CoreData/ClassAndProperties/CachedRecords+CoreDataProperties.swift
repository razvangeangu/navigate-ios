//
//  CachedRecords+CoreDataProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 26/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData


extension CachedRecords {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedRecords> {
        return NSFetchRequest<CachedRecords>(entityName: "CachedRecords")
    }

    @NSManaged public var modificationDate: NSDate?
    @NSManaged public var recordName: String?

}
