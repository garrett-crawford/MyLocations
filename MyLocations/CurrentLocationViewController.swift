//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 1/31/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit
import CoreData

// import this to include CoreLocation services
import CoreLocation

// this framework provides Core Animation
import QuartzCore

// this framework provides system sounds to play
import AudioToolbox

// must make the view controller conform to the CoreLocation protocol
class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate
{
    // UI properties
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var latitudeTextLabel: UILabel!
    @IBOutlet weak var longitudeTextLabel: UILabel!
    
    // container view that contains all of the other views for the animation
    @IBOutlet weak var containerView: UIView!
    
    // 'CLLocationManager' is the object that will give GPS coordinates
    let locationManager = CLLocationManager()
    
    // this will store the user's current location 
    // needs to be an optional, because it's possible to not have a location
    var location: CLLocation?
    
    var updatingLocation = false
    
    // in the case of a more serious error, store the error object into an ivar
    // that way you can look up later what kind of error you are dealing with
    // comes in useful in 'updateLabels()'
    var lastLocationError: NSError?
    
    // object that will perform the geocoding
    let geocoder = CLGeocoder()
    
    // object the contains the address results (from the geocoding)
    // must be an optional because it may have no value or when the location doesn't correspond to an address
    var placemark: CLPlacemark?
    
    var performingReverseGeocoding = false
    
    // contains the error if something goes wrong with geocoding
    var lastGeocodingError: NSError?
    
    var timer: NSTimer?
    
    var managedObjectContext: NSManagedObjectContext!
    
    // 0 means no sound has been loaded yet (also of type SystemSoundID, not int, hence explicitly defining the type)
    var soundID: SystemSoundID = 0
    
    var logoVisible = false
    
    // logo image is actually a button you can tap to get started
    // button is a custom type UIButton
    // it draws "Logo.png" and calls getLocation when tapped()
    // also laziliy loaded
    lazy var logoButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setBackgroundImage(UIImage(named: "Logo"), forState: .Normal)
        button.sizeToFit()
        button.addTarget(self, action: Selector("getLocation"), forControlEvents: .TouchUpInside)
        button.center.x = CGRectGetMidX(self.view.bounds)
        button.center.y = 220
        return button
    }()
    
    // hides the container view so that the labels disappear, and puts the logoButton object on the screen
    // this is the first time logoButton is accessed, so at this point the lazy loading kicks in
    func showLogoView() {
        if !logoVisible {
            logoVisible = true
            containerView.hidden = true
            view.addSubview(logoButton)
        }
    }
    
    // removes the button with the logo and un-hides the container view with the GPS coordinates
    // creates three animations that are played at the same time
    func hideLogoView() {
        if !logoVisible { return }
        
        logoVisible = false
        containerView.hidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        let centerX = CGRectGetMidX(view.bounds)
        
        // the containerView is placed outside the screen (somewhere on the right)
        // and moved to the center
        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.removedOnCompletion = false
        panelMover.fillMode = kCAFillModeForwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(CGPoint: containerView.center)
        panelMover.toValue = NSValue(CGPoint: CGPoint(x: centerX, y: containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        panelMover.delegate = self
        containerView.layer.addAnimation(panelMover, forKey: "panelMover")
        
        // the logo image view slides out of the screen
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.removedOnCompletion = false
        logoMover.fillMode = kCAFillModeForwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(CGPoint: logoButton.center)
        logoMover.toValue = NSValue(CGPoint: CGPoint(x: -centerX, y: logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoMover, forKey: "logoMover")
        
        // at the same time the logo image is rotated around its center
        // gives the impression that it's rolling away
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.removedOnCompletion = false
        logoRotator.fillMode = kCAFillModeForwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * M_PI
        logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        logoButton.layer.addAnimation(logoRotator, forKey: "logoRotator")
    }
    
    // cleans up after the animations and removes the logo button
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        containerView.layer.removeAllAnimations()
        containerView.center.x = view.bounds.size.width / 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
        
        logoButton.layer.removeAllAnimations()
        logoButton.removeFromSuperview()
    }

    override func viewDidLoad()
    {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
        loadSoundEffect("Sound.caf")
    }
    
    // returns documents directory
    
    // when changing the data model during development, throw away the database file or Core Data
    // cannot be initialized properly (just find the database file in the documents directory)
    // if updating app that has already been released (changing the data model), use the migration 
    // mechanism in Core Data
    func applicationDocumentsDirectory() -> String
    {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0];
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

    @IBAction func getLocation()
    {
        /* checks current authorization status */
        
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .NotDetermined
        {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // shows the alert if the authorization status is denied or restricted
        if authStatus == .Denied || authStatus == .Restricted
        {
            showLocationServicesDeniedAlert()
            return
        }
        
        if logoVisible {
            hideLogoView()
        }
        
        // if the button is pressed while the app is looking for a location, stop the location manager
        if updatingLocation
        {
            stopLocationManager()
        }
        
        else
        {
            // clear out old location and error objects before searching for a new location
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        
        updateLabels()
        configureGetButton()
    }
    
    // screen transition
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "TagLocation"
        {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            // force unwrap the 'location' optional because by the time this segue can only be performed
            // if the user has coordinates (so it will never be nil here)
            controller.coordinate = location!.coordinate
            controller.placemark = placemark;
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    func showLocationServicesDeniedAlert()
    {
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .Alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        
        alert.addAction(okAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateLabels()
    {
        // unwrap optional
        if let location = location
        {
            // creates a format string using "%.8f" and the value to replace in that string
            // placeholders start with a % sign
            // the "%.8f" means that the value for each coordinate should be to 8 decimal places
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            
            if let placemark = placemark
            {
                addressLabel.text = stringFromPlacemark(placemark)
            }
            
            else if performingReverseGeocoding
            {
                addressLabel.text = "Searching for ddress..."
            }
            
            else if lastGeocodingError != nil
            {
                addressLabel.text = "Error finding address"
            }
            
            else
            {
                addressLabel.text = "No address found"
            }
            
            latitudeTextLabel.hidden = false
            longitudeTextLabel.hidden = false
        }
        
        else
        {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            
            // all of the code below determines what to put in the message label at the top of the screen
            let statusMessage: String
            if let error = lastLocationError
            {
                // if this is true, the user has not given the app permission to use location services
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue
                {
                    statusMessage = "Location services disabled"
                }
                
                    // if the error code is something else, then we set the message to be this
                    // as this usually means there was no way of obtaining a location fix
                else
                {
                    statusMessage = "Error getting location"
                }
            }
            
            // if the user has disabled location services completely on the device, check
            // for that situation here
            else if !CLLocationManager.locationServicesEnabled()
            {
                statusMessage = "Location Services Disabled"
            }
            
            // if there are no errors, status label will say "Searching..." before the first
            // location object is received
            else if updatingLocation
            {
                statusMessage = "Searching..."
            }
            
            else
            {
                statusMessage = ""
                showLogoView()
            }
            
            messageLabel.text = statusMessage
            
            latitudeTextLabel.hidden = true
            longitudeTextLabel.hidden = true
            
        }
    }
    
    func startLocationManager()
    {
        // checks to see if location services are enabled
        if CLLocationManager.locationServicesEnabled()
        {
            // declare this view controller to be the delegate of 'locationManager', and
            // that we want to receive locations with an accuracy of up to ten meters
            // then start the location manager
            // from that moment, the CLLocationManager object will send location updates to its delegate
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            // sets up a timer object that sends out the 'didTimeOut' message to self after 60 seconds
            // 'didTimeOut' is the name of the method you provide
            timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager()
    {
        if updatingLocation
        {
            // cancel the timer in case the location manager is stopped before the time-out fires
            // this happens when an accurate enough location is found within one minute after starting, or 
            // when the stop button is tapped
            if let timer = timer
            {
                timer.invalidate()
            }
            
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    // always called after one minute, unless stopLocationManager() cancels it
    // if after that one minute there is still no valid location, you stop the location manager,
    // and create your own error code and update the screen
    // by creating your own NSError object and putting it into 'lastLocationError', don't have to change
    // any logic in updateLabels()
    func didTimeOut()
    {
        print("*** Time out")
        
        if location == nil
        {
            stopLocationManager()
            
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
    
    // if the app is currently updating the location then the button's title becomes "Stop"
    // also creates a new instance of UIActivityIndicatorView and position the the spinner view
    // below the message label at the top of the screen
    func configureGetButton()
    {
        let spinnerTag = 1000
        
        if updatingLocation
        {
            getButton.setTitle("Stop", forState: .Normal)
            
            if view.viewWithTag(spinnerTag) == nil {
                let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
                
                spinner.center = messageLabel.center
                spinner.center.y += spinner.bounds.size.height / 2 + 15
                spinner.startAnimating()
                spinner.tag = spinnerTag
                containerView.addSubview(spinner)
            }
        }
        
        else
        {
            getButton.setTitle("Get My Location", forState: .Normal)
            
            if let spinner = view.viewWithTag(spinnerTag) {
                spinner.removeFromSuperview()
            }
        }
    }
    
    func stringFromPlacemark(placeMark: CLPlacemark) -> String
    {
        var line1 = ""
        line1.addText(placeMark.subThoroughfare)
        line1.addText(placeMark.thoroughfare)
        
        var line2 = ""
        line2.addText(placeMark.locality)
        line2.addText(placeMark.administrativeArea)
        line2.addText(placeMark.postalCode)
        
        line1.addText(line2, withSeparator: "\n")
        return line1
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError)
    {
        print("didFailWithError \(error)")
        
        // CLError.LocationUnknown means that the location manager was unable to obtain a loctaion
        if error.code == CLError.LocationUnknown.rawValue
        {
            return
        }
        
        lastLocationError = error
        
        // if obtaining a location appears to be impossible for wherever the user is on the globe,
        // then you tell the location manager to stop
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager, locations: [CLLocation])
    {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        // if the time at which the location object was determined is too long ago (5 seconds),
        // then this is a cached result
        // instead of returning a new location, the location manager may initially give the most
        // recently found location under the assumption that you might not have moved since the last time
        // simply ignore the cached locations if they are too old
        if newLocation.timestamp.timeIntervalSinceNow < -5
        {
            return
        }
        
        // this determines whether new readings are more accurate than previous ones
        if newLocation.horizontalAccuracy < 0
        {
            return
        }
        
        // this calculates the distance between the new reading and the old one, if there was one
        // if there was no previous reading, then the distance is 'DBL_MAX' (the max number a float value can have)
        // this little trick gives it a gigantic distance if this is the very first reading
        // do this so that any of the following calculations will still work even if not able to calculate
        // a true distance yet
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location
        {
            distance = newLocation.distanceFromLocation(location)
        }
        
        // this determines if the new reading is more useful than the previous one
        // if this is the very first location reading or the new location is more accurate
        // than the previous reading, continue
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy
        {
            // this is set to nil in case a valid location is to come in after an error was previously set
            // this clears out the old error state
            lastLocationError = nil
            location = newLocation
            
            // store the CLLocation object that you get from the location manager into 'location'
            updateLabels()
            
            // if the new location's accuracy is equal to or better than the desired accuracy,
            // stop asking the location manager for updates
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy
            {
                print("*** We're done!")
                stopLocationManager()
                configureGetButton()
                
                // this forces a reverse geocoding for the final location, even if the app is already currently
                // performing another geocoding request
                // you want the address for that final location, as it's the most accurate you've found
                if distance > 0
                {
                    performingReverseGeocoding = false
                }
            }
            
            // the app should only perform a single reverse geocoding request at a time, so first
            // check to see whether or not it is busy yet before starting the geocoder
            if !performingReverseGeocoding
            {
                print("*** Going to geocode")
                
                performingReverseGeocoding = true
                
                // this is an example of a Swift 'closure'
                // a closure is a block of code that is written inline instead of a separate method
                // the code inside a closure is not usually executed immediately but is stored and performed 
                // at some later point 
                // unliked the rest of the code inside of this method, the code in this closure is not performed right away
                // the closure is kept for later by the CLGeocoder object and is only performed after CLGeocoder finds an
                // address or encounters an error
                // the closure is tells the CLGeocoder object that you want to reverse geocode the location, and that the code
                // in the block following 'completionHandler:' should be executed as soon as the geocoding is completed
                // 'placemarks, error' are the parameters for the closure
                // when the geocoder finds a result for the location object 'newLocation', it invokes this closure
                // 'placemarks' will contain an array of CLPlacemark objects that describe the address information,
                // and 'error' contains an error message if something goes wrong
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
                    placemarks, error in
                    
                    // print("*** Found placemarks: \(placemarks), error: \(error)")
                    
                    self.lastGeocodingError = error
                    
                    // if there is no error and there are objects in the placemarks array, then you take the last one
                    // usually there will be only one CLPlacemark object in the array, but there can exist a
                    // situation where one location coordinate may refer to more than one address
                    // this app can only handle one address at a time, so we just pick the last one (usually the only one)
                    // 'let p = placemarks' unwraps the optional, and we should only enter the statement if the array
                    // of placemarks is not empty
                    if error == nil, let p = placemarks where !p.isEmpty
                    {
                        if self.placemark == nil {
                            print("FIRST TIME!")
                            self.playSoundEffect()
                        }
                        
                        // 'p.last!' refers to the last item in the array
                        // it's an optional because there is no such item if the array is empty
                        self.placemark = p.last!
                    }
                    
                    // if there was an error during geocoding, set 'self.placemark' to nil
                    else
                    {
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
        }
        
        // if the coordinate from this reading is not significantly different from the previous reading and it has
        // been more than 10 seconds since the last reading, then stop
        else if distance < 1.0
        {
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            
            if timeInterval > 10
            {
                print("*** Force done!")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }
    
    // MARK: - Sound Effect
    
    func loadSoundEffect(name: String) {
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: nil) {
            let fileURL = NSURL.fileURLWithPath(path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL, &soundID)
            if error != kAudioServicesNoError {
                print ("Error code \(error) loading sound at path: \(path)")
            }
        }
    }
    
    func unloadSoundEffect() {
        AudioServicesDisposeSystemSoundID(soundID)
        soundID = 0
    }
    
    func playSoundEffect() {
        AudioServicesPlaySystemSound(soundID)
    }
    
}

