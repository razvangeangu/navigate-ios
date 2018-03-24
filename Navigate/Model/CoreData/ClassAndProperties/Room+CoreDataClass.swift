//
//  Room+CoreDataClass.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Room)
public class Room: NSManagedObject, Encodable, Decodable {

    enum CodingKeys: String, CodingKey {
        case name
        case tiles
        case floor
    }
    
    required public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextUserInfoKey = CodingUserInfoKey.context,
            let managedObjectContext = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Floor", in: managedObjectContext) else {
                fatalError("Failed to decode Floor!")
        }
        self.init(entity: entity, insertInto: nil)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        tiles = NSSet(array: try values.decode([Tile].self, forKey: .tiles))
        floor = try values.decode(Floor.self, forKey: .floor)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        // try container.encode(tiles?.allObjects as? [Tile], forKey: .tiles)
        // try container.encode(floor, forKey: .floor)
    }
}
