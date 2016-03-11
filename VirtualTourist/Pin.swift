//
//  Pin.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-03-03.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit
import CoreData

class Pin : NSManagedObject {
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
    }
    
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var photos: [Photo]
    @NSManaged var flickrPage: NSNumber
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        longitude = dictionary[Keys.Latitude] as! NSNumber
        latitude = dictionary[Keys.Longitude] as! NSNumber
        flickrPage = 1
    }
    
    
    init(longitude: NSNumber, latitude: NSNumber, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        self.longitude = longitude
        self.latitude = latitude
        flickrPage = 1
    }
}
