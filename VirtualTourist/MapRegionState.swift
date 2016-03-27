//
//  MapRegionState.swift
//  VirtualTourist
//
//  Created by Paul Salinas on 2016-03-27.
//  Copyright © 2016 Paul Salinas. All rights reserved.
//

import UIKit
import CoreData

class MapRegionState : NSManagedObject {
    
    @NSManaged var longitude: NSNumber
    @NSManaged var latitude: NSNumber
    @NSManaged var latitudeDelta: NSNumber
    @NSManaged var longitudeDelta: NSNumber
    @NSManaged var altitude: NSNumber
    @NSManaged var pitch: NSNumber
    @NSManaged var heading: NSNumber

    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(longitude: NSNumber,
         latitude: NSNumber,
         latitudeDelta: NSNumber,
         longitudeDelta: NSNumber,
         altitude: NSNumber,
         pitch:  NSNumber,
         heading: NSNumber,
         context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("MapRegionState", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        self.longitude = longitude
        self.latitude = latitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
        self.altitude = altitude
        self.pitch = pitch
        self.heading = heading
    }
}
