//
//  AccessPoint+CoreDataClass.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData

@objc(AccessPoint)
public class AccessPoint: NSManagedObject, Encodable, Decodable {

    enum CodingKeys: String, CodingKey {
        case strength
        case uuid
    }
    
    required public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextUserInfoKey = CodingUserInfoKey.context,
            let managedObjectContext = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "AccessPoint", in: managedObjectContext) else {
                fatalError("Failed to decode AccessPoint!")
        }
        self.init(entity: entity, insertInto: nil)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        strength = try values.decode(Int64.self, forKey: .strength)
        uuid = try values.decode(String.self, forKey: .uuid)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(strength, forKey: .strength)
        try container.encode(uuid, forKey: .uuid)
    }
}
