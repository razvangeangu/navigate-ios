//
//  Tile+CoreDataClass.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Tile)
public class Tile: NSManagedObject, Encodable, Decodable {
    
    enum CodingKeys: String, CodingKey {
        case col
        case row
        case type
        case accessPoints
        case room
    }
    
    required public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextUserInfoKey = CodingUserInfoKey.context,
            let managedObjectContext = decoder.userInfo[contextUserInfoKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Tile", in: managedObjectContext) else {
                fatalError("Failed to decode Tile!")
        }
        self.init(entity: entity, insertInto: nil)
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        col = try values.decode(Int16.self, forKey: .col)
        row = try values.decode(Int16.self, forKey: .row)
        type = try values.decode(String.self, forKey: .type)
        accessPoints = NSSet(array: try values.decode([AccessPoint].self, forKey: .accessPoints))
        room = try values.decode(Room.self, forKey: .room)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(col, forKey: .col)
        try container.encode(row, forKey: .row)
        try container.encode(type, forKey: .type)
        try container.encode(accessPoints?.allObjects as? [AccessPoint], forKey: .accessPoints)
        try container.encode(room, forKey: .room)
    }
}


