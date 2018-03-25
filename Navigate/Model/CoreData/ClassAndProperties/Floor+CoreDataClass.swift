//
//  Floor+CoreDataClass.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 19/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//
//
// https://stackoverflow.com/questions/44450114/how-to-use-swift-4-codable-in-core-data/46917019 For Encodable, Decodable

import Foundation
import CoreData
import CloudKit

@objc(Floor)
public class Floor: NSManagedObject, Encodable, Decodable {
    
    enum CodingKeys: String, CodingKey {
        case level
        case image
        case tiles
        case rooms
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
        level = try values.decode(Int16.self, forKey: .level)
        image = try values.decode(String.self, forKey: .image).data(using: .utf8) as NSData?
        tiles = NSSet(array: try values.decode([Tile].self, forKey: .tiles))
        rooms = NSSet(array: try values.decode([Room].self, forKey: .rooms))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        if image != nil {
            if let imageData = image?.base64EncodedData(options: .endLineWithLineFeed) {
                try container.encode(imageData, forKey: .image)
            }
        } else {
            try container.encode("", forKey: .image)
        }
        try container.encode(tiles?.allObjects as? [Tile], forKey: .tiles)
        try container.encode(rooms?.allObjects as? [Room], forKey: .rooms)
    }
}
