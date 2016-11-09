//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/14/16.
//  Copyright © 2016 Noox. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import CoreLocation

// using an extension can add additional functionality to an existing object without having to change 
// the source code for that object
extension Location
{
    // these properties are created by Xcode from the attributes specified in the data model editor
    // @NSManaged tells the compiler that these properties will be resolved at runtime by Core Data
    // when a new value is put into one of these properties, Core Data will place that value into 
    // the data store for safekeeping (instead of a regular instance variable)
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var date: NSDate
    @NSManaged var locationDescription: String
    @NSManaged var category: String
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var photoID: NSNumber?

}
