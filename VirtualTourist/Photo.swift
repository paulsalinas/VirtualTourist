//
//  Photo.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-03-03.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    
    
    @NSManaged var imagePath: String?
    @NSManaged var id: NSNumber
    @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], pin: Pin, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        imagePath = dictionary["imagePath"] as? String
        id = dictionary["id"] as! Int
        self.pin = pin
    }
    
    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }
}



