//
//  CloudKitManagerObjectsExtension.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 28/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

extension CloudKitManager {
    
    /**
     A function to retrieve an entity object from core data with a record name.
     
     - parameter in context: The context of the object from which is to be retrieved.
     - parameter recordName: The record name of the object as a **String** that contains the unique id
     of the record.
     
     - Returns: An optional **NSManagedObject** that represents the requested object.
     */
    static func object(in context: NSManagedObjectContext, recordName: String) -> NSManagedObject? {
        
        // Split the record name by . which returns the record type and the unique identifier
        if let dotIndex = recordName.index(of: ".") {
            
            // Get the entity name
            let entityName = String(recordName[...recordName.index(before: dotIndex)])
            
            do {
                // Get all entities in the context
                let entities = try context.fetch(NSFetchRequest(entityName: entityName))
                
                // For each entity found
                for case let entity as CloudKitManagedObject in entities {
                    
                    // If the entity is found based on the record name
                    if entity.recordName == recordName {
                        
                        // Return the entity
                        return entity as? NSManagedObject
                    }
                }
            } catch {
                
                // Update UI
                MapViewController.devLog(data: "Error in Floor fetchRequest")
            }
        }
        
        // Return *nil* if object can not be found
        return nil
    }
    
    /**
     A function that retrieves entity objects from core data with a record name.
     
     - parameter entityName: The entity name for the objects to be retrieved.
     - parameter in context: The context in the local database from which the objects are to be retrieved.
     - parameter withRecordName name: The record name for the entities to be identified.
     
     - Returns: An optional sequence of **NSManagedObject** that represents the requested objects.
     */
    static func objects(entityName: String, in context: NSManagedObjectContext, withRecordName name: String) -> [CloudKitManagedObject]? {
        
        // Initiliase the sequence
        var entitiesToReturn = [CloudKitManagedObject]()
        
        do {
            
            // Get all the entities from the context
            let entities = try context.fetch(NSFetchRequest(entityName: entityName))
            
            // For each entity found
            for case let entity as CloudKitManagedObject in entities {
                
                // Match the record name
                if entity.recordName == name {
                    
                    // Append it to the sequence
                    entitiesToReturn.append(entity)
                }
            }
            
            // If entities have been found
            if !entitiesToReturn.isEmpty {
                
                // Return the found entities
                return entitiesToReturn
            }
        } catch {
            MapViewController.devLog(data: "Error in Floor fetchRequest")
        }
        
        // Return *nil* if objects can not be found
        return nil
    }
    
    /**
     A function that retrieves entity objects from core data.
     
     - parameter entityName: The entity name of the objects to be found.
     - parameter in context: The context in the local database from which the objects are to be retrieved.
     
     - Returns: An optional sequence of **NSManagedObject** that represents the requested objects.
     */
    static func objects(entityName: String, in context: NSManagedObjectContext) -> [NSManagedObject]? {
        
        // Initiliase the sequence
        var entitiesToReturn = [NSManagedObject]()
        
        do {
            
            // Get all the entities from the context
            let entities = try context.fetch(NSFetchRequest(entityName: entityName))
            
            // For each entity found
            for case let entity as NSManagedObject in entities {
                
                // Append the entity
                entitiesToReturn.append(entity)
            }
            
            // If entities have been found
            if !entitiesToReturn.isEmpty {
                
                // Return the found entities
                return entitiesToReturn
            }
        } catch {
            MapViewController.devLog(data: "Error in Floor fetchRequest")
        }
        
        // Return *nil* if objects can not be found
        return nil
    }
    
    /**
     A function to update the object from the local database based on the records provided.
     
     - parameter for records: A sequence of records that contain the new data.
     */
    static func updateObject(for records: [CKRecord]) {
        
        // For each record
        for record in records {
            
            // Get the record name
            let recordName = record.recordID.recordName
            
            // Get the managed object from the update context
            if let managedObject = object(in: updateContext, recordName: recordName) as? CloudKitManagedObject {
                
                // Check the last update date for the object found
                if let lastUpdate = record["lastUpdate"] as? Date {
                    
                    // If the record is newer than the object
                    if lastUpdate.compare(managedObject.lastUpdate! as Date) == .orderedDescending {
                        
                        // Update the object with the record data
                        managedObject.update(with: record)
                    }
                }
            
            // If the object does not exists in the context
            } else {
                
                // Split the record name
                if let dotIndex = recordName.index(of: ".") {
                    
                    // Get the entity name
                    let entityName = String(recordName[...recordName.index(before: dotIndex)])
                    
                    // Insert the new object in the update context
                    let newObject = NSEntityDescription.insertNewObject(forEntityName: entityName, into: updateContext)
                    
                    // If the object has been successfuly created
                    if let cloudManagedObject = newObject as? CloudKitManagedObject {
                        
                        // Update the object with the record data.
                        cloudManagedObject.update(with: record)
                    }
                }
            }
        }
    }
    
    /**
     A function that deletes objects based on the record names using the update context.
     
     - parameter recordNames: A sequence of strings that represent the record types with their unique identifier.
     */
    static func deleteObject(recordNames: [String]) {
        
        // For each record name
        for recordName in recordNames {
            
            // If there is an existent object for the record name in the update context
            if let object = object(in: updateContext, recordName: recordName) {
                
                // Delete the object from the local database
                updateContext.delete(object)
            }
        }
    }
}
