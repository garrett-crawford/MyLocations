//
//  MapViewController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 3/8/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    // as soon as managedObjectContext is given a value, the didSet block tells the NSNotificationCenter to add an observer
    // for the NSManagedObjectContextObjectsDidChangeNotification 
    // this notification with the very long name is sent out by the managedObjectContext whenever the data store changes
    // in response, the following closure is called
    var managedObjectContext: NSManagedObjectContext! {
        didSet {
            NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext, queue: NSOperationQueue.mainQueue()) { notification in
                if self.isViewLoaded() {
                    self.updateLocations()
                }
            }
        }
    }
    
    var locations = [Location]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocations()
        
        if !locations.isEmpty {
            showLocations()
        }
    }
    
    // executed every time there is a change in the data store
    // an "annotation" is a pin on the map
    func updateLocations() {
        
        // the locations array may already exist and contain objects, so tell the map view
        // to remove the pins for these old objects
        mapView.removeAnnotations(locations)
        
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedObjectContext)
        
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        
        // if you are certain that a particular method call will never fail, you can dispense the 'do' and
        // 'catch' keys and just write 'try!'
        locations = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Location]
        
        // once the location objects have been obtained, this is called to add a pin for each location on the map
        mapView.addAnnotations(locations)
    }
    
    // by looking at the highest and lowest values for the latitude and longitude of all the Location objects,
    // you can calculate a region and then tell the map view to zoom to that region
    func regionForAnnotations(annotations: [MKAnnotation]) -> MKCoordinateRegion {
        var region: MKCoordinateRegion
        
        // either there are no annotations (center the map on the user's current position)
        // there is only one annotation (center the map on that one annotation)
        // there are two or more annotations (calculate the extent of their reach and add some extra space)
        // does not use Location objects for anything (assumes that all objects in the 'MKAnnotation' array
        // conform to the MKAnnotation protocol, in which this case the Location class does)
        switch annotations.count {
            case 0:
              region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 100, 100)
            
            case 1:
              let annotation = annotations[annotations.count - 1]
              region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
            
            default:
              var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
              var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            
              for annotation in annotations {
                topLeftCoord.latitude = max(topLeftCoord.latitude, annotation.coordinate.latitude)
                topLeftCoord.longitude = min(topLeftCoord.longitude, annotation.coordinate.longitude)
                bottomRightCoord.latitude = min(bottomRightCoord.latitude, annotation.coordinate.latitude)
                bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotation.coordinate.longitude)
              }
            
              let center = CLLocationCoordinate2D(latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2, longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
            
              let extraSpace = 1.1
              let span = MKCoordinateSpan(latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace, longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
            
              region = MKCoordinateRegion(center: center, span: span)
        }
        
        return mapView.regionThatFits(region)
    }
    
    func showLocationDetails(sender: UIButton) {
        performSegueWithIdentifier("EditLocation", sender: sender)
    }
    
    // because the segue isn't connected with any particular control in the view controller, 
    // you have to perform it manually here (pass along the button object as the sender, so
    // you can read its tag property in prepareForSegue())
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            controller.managedObjectContext = managedObjectContext
            
            let button = sender as! UIButton
            let location = locations[button.tag]
            controller.locationToEdit = location
        }
    }
    
    @IBAction func showUser() {
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    // calls regionForAnnotations() to calculate a reasonable region that fits all the Location objects and sets that
    // region on the map view
    @IBAction func showLocations() {
        let region = regionForAnnotations(locations)
        mapView.setRegion(region, animated: true)
    }
    
}

// map view delegate
extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        // because MKAnnotation is a protocol, there may be other objects that aren't Location objects that
        // want to be annotations on the map
        // use the special 'is' type check operator to determine whether the annotation is really a Location object
        // if it isn't, return nil to signal that you're not making an annotation for this other kind of object
        guard annotation is Location else {
            return nil
        }
        
        // ask the map view to reuse an annotation view object
        // if it cannot find a recyclable annotation view, then create a new one
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            // configure the look and feel of the annotation view (previously pins were red, they are made green here)
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.animatesDrop = false
            annotationView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            
            // set annotation color to half-opaque black
            annotationView.tintColor = UIColor(white: 0.0, alpha: 0.5)
            
            // create a new UIButton object that looks like a detail disclosure button
            // use target-action pattern to hook up the button's "Touch Up Inside" event with a new 
            // showLocationDetails() method, and add the button to the annotation view's accessory
            let rightButton = UIButton(type: .DetailDisclosure)
            rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)
            annotationView.rightCalloutAccessoryView = rightButton
        } else {
            annotationView.annotation = annotation
        }
        
        // once the annotation view is configured, obtain a reference to that detail disclosure button 
        // and set its tag to the index of the Location object in the locations array
        // that way you can find the location object later in showLocationDetails() when the button is pressed
        let button = annotationView.rightCalloutAccessoryView as! UIButton
        if let index = locations.indexOf(annotation as! Location) {
            button.tag = index
        }
        
        return annotationView
    }
}

// tells the navigation bar to extend under the status bar area
extension MapViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}