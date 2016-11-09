//
//  Location.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/14/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import Foundation
import CoreData
import MapKit

// make the Location class conform to the MKAnnotation protocol (for map annotation functionality)
// the MKAnnotaion protocol requires three properties to be implemented: coordinate, title, and subtitle
// MKAnnotation protocol allows you to pretend that some class X is an annotation that can be placed on a map view
class Location: NSManagedObject, MKAnnotation
{
    // all three of these instance variables are read-only computed properties 
    // they don't actually store a value into a memory location
    // whenever you access these variables, they perform the logic from their code blocks (aka computed properties)
    // they are read-only because they only return a value (can't give them a new value)
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title: String? {
        if locationDescription.isEmpty {
            return "(No Description)"
        } else {
            return locationDescription
        }
    }
    
    var subtitle: String? {
        return category
    }
    
    // determines whether the location object has a photo or not
    var hasPhoto: Bool {
        return photoID != nil
    }
    
    // computes the file path to the jpeg file for the photo 
    // these files will be saved in the Documents Directory
    var photoPath: String {
        // an assertion is used to to check that code always does something valid
        // if not, the app will crash with a helpful error message
        assert(photoID != nil, "No photo ID set")
        let filename = "Photo-\(photoID!.integerValue).jpg"
        return (applicationDocumentsDirectory as NSString).stringByAppendingPathComponent(filename)
    }
    
    // returns a UIImage by loading the image file
    // optional because the file loading may fail if the file is damaged or removed
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoPath)
    }
    
    // class method (don't need a Location object to call it)
    // you need to have some way to generate a unique ID for each Location object
    // put a simple integer in NSUserDefaults and update it every time the app asks for a new ID
    class func nextPhotoID() -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let currentID = userDefaults.integerForKey("PhotoID")
        userDefaults.setInteger(currentID + 1, forKey: "PhotoID")
        userDefaults.synchronize()
        return currentID
    }
    
    // removes the file containing the photo
    func removePhotoFile() {
        if hasPhoto {
            let path = photoPath
            
            let fileManger = NSFileManager.defaultManager()
            if fileManger.fileExistsAtPath(path) {
                do {
                    try fileManger.removeItemAtPath(path)
                } catch {
                    print("Error removing file: \(error)")
                }
            }
            
        }
    }

}
