//
//  TagLocationViewController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/4/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

// create a new constant of 'NSDateFormatter'
// constant is private (can't be used outside of this swift file)
// this gives 'dateFormatter' an initial value using a closure
// inside the closure is the code that creates and initializes the new 'NSDateFormatter' object, and returns it
// the '()' at the end of the block evaluates the closure, and returns the 'NSDateFormatter' object
// this won't be created until the app needs it (known as "lazy loading")
// this is a private global constant
private let dateFormatter: NSDateFormatter =
{
    let formatter = NSDateFormatter()
    formatter.dateStyle = .MediumStyle
    formatter.timeStyle = .ShortStyle
    return formatter
}()

class LocationDetailsViewController: UITableViewController
{
    // storyboard outlets
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    // contains the latitude and longitude from the CLLocation object received from the location manager
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    // 'CLPlacemark' contains address information (optional because no guarantee geocoder will find an address)
    var placemark: CLPlacemark?
    
    var categoryName = "No Category"
    
    var managedObjectContext: NSManagedObjectContext!
    
    // *property observer*
    // if a variable has a didSet block, then the code in this block is performed
    // whenever you put a new value into the variable (in this case, the code will be
    // performed when the optional is not nil and is unwrapped)
    var locationToEdit: Location?
    {
        didSet
        {
            if let location = locationToEdit
            {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                
                placemark = location.placemark
            }
        }
    }
    
    var descriptionText = ""
    
    // stores the current date in the new Location object
    var date = NSDate()
    
    // optional in the case that no photo is picked yet
    var image: UIImage?
    
    // holds a reference to the observer (necessary to unregister it later)
    var observer: AnyObject!
    
    // this method stops the NSNotificationCenter from sending background notifications when the Tag/Edit location screen closes
    deinit {
        print("*** deinit \(self)")
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
    
    // updates the view controller to contain relevant address information from previous screen
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        listenForBackgroundNotification()
        
        if let location = locationToEdit
        {
            title = "Edit Location"
            
            if location.hasPhoto {
                if let image = location.photoImage {
                    showImage(image)
                }
            }
        }
        
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark
        {
            addressLabel.text = stringFromPlacemark(placemark)
        }
        
        else
        {
            addressLabel.text = "No address found"
        }
        
        dateLabel.text = formatDate(date)
        
        // a gesture recognizer is an object that recognizes touches and other finger movements
        // create the object, give it a method to call when that particular gesture has been observed to take place,
        // and add recognizer to the view
        // target-action
        // here the selector sends the 'hideKeyboard' method when a tap is recognized anywhere in the table view
        // (must implement hideKeyboard(), the ':' in the method name indicates the method takes a single parameter
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard:"))
        
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
        
        descriptionTextView.textColor = UIColor.whiteColor()
        descriptionTextView.backgroundColor = UIColor.blackColor()
        
        addPhotoLabel.textColor = UIColor.whiteColor()
        addPhotoLabel.highlightedTextColor = addPhotoLabel.textColor
        
        addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        addressLabel.highlightedTextColor = addressLabel.textColor
    }
    
    // puts the image into the image view, makes the image view visible and gives it the proper dimensions
    // also hides the add photo label
    func showImage(image: UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.hidden = true
    }
    
    // whenever the user taps somewhere in the table view, the gesture recognizer calls thid method
    // passes a reference to itself as the parameter (to ask gestureRecognizer where the tap happened)
    func hideKeyboard(gestureRecognizer: UITapGestureRecognizer)
    {
        // returns a CGPoint to designate where in the view the user has tapped
        let point = gestureRecognizer.locationInView(tableView)
        
        // finds which index path is currently being displayed at that point
        let indexPath = tableView.indexPathForRowAtPoint(point)
        
        // if the user taps the description cell (where the keyboard should stay up), return
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0
        {
            return
        }
        
        // any tap that is not on the description cell can remove the keyboard
        descriptionTextView.resignFirstResponder()
    }
    
    // no newlines necessary here because UILabel's word-wrap
    func stringFromPlacemark(placemark: CLPlacemark) -> String
    {
        var line = ""
        
        line.addText(placemark.subThoroughfare)
        line.addText(placemark.thoroughfare, withSeparator: " ")
        line.addText(placemark.locality, withSeparator: ", ")
        line.addText(placemark.administrativeArea, withSeparator: ", ")
        line.addText(placemark.postalCode, withSeparator: " ")
        line.addText(placemark.country, withSeparator: ", ")
        
        return line
    }
    
    func formatDate(date: NSDate) -> String
    {
        return dateFormatter.stringFromDate(date)
    }
    
    @IBAction func cancel()
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done()
    {
        
        
        // creates a HudView object and adds it to the navigation controller's view with an animation
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        
        let location: Location
        
        // unwraps when the user is updating a location
        if let temp = locationToEdit
        {
            hudView.text = "Updated"
            location = temp
        }
        
        // ask Core Data for a Location object if adding a new one
        else
        {
            hudView.text = "Tagged"
            
            // create a new location object
            // because this is a Core Data managed object, creating an instance of this is different
            // must ask the NSEntityDescription class to insert a new object for your entity into the
            // managed object context (this is the way you make instances using Core Data)
            // "Location" is the name of the entity that was previously added earlier in the data model
            location = NSEntityDescription.insertNewObjectForEntityForName("Location",
                inManagedObjectContext: managedObjectContext) as! Location
            
            // set this to nil so that the hasPhoto property correctly recognizes that these Location objects
            // do not have a photo yet (photoID has a default value of 0 when creating a new Location object,
            // so set it = nil here)
            location.photoID = nil
        }
        
        // once Location object is created, set properties to whatever the user entered in the screen
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        // only performed if the user has picked a photo
        if let image = image {
            
            // need to get a new ID and assign it to the Location's photoID property (if the location doesn't already have a photo)
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID()
            }
            
            // UIImageJPEGRepresentation converts the UIImage into JPEG format and returns an NSData object
            // NSData is an object that represents a blob of binary data (usually the contents of a file)
            if let data = UIImageJPEGRepresentation(image, 0.5) {
                
                // save the NSData object to the path given by photoPath
                do {
                    try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
                } catch {
                    print("Error writing file: \(error)")
                }
            }
        }
        
        // save the Location object that was added to the managed object context and write the changes
        // into the data store (this also works for changing an objects contents that already exists in the managed object context)
        do
        {
            try managedObjectContext.save()
        } catch {
            fatalCoreDataError(error)
        }
        
        
        // inside the closure, tell the view controller to dimiss itself
        // this doesn't happen right away though (that's the power of closures)
        // even though this code is written alongside everything else, it's execution is ignored for now
        // and kept for a later time
        // also note the use of self to call dismissViewController (must use self inside a closure)
        // Swift has a useful rule that allows you to put a closure behind a function call if it's
        // the last parameter (this is called trailing closure syntax)
        afterDelay(0.6) {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // set the 'selectedCategoryName' property of the category picker
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "PickCategory"
        {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    // "unwind segue"
    // in order to make an unwind segue, you need to define an action method that takes a UIStoryboardSegue parameter
    @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue)
    {
        let controller = segue.sourceViewController as! CategoryPickerViewController
        
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // MARK: - UITableViewDelegate
    
    // this method is called when the table view loads its cells (use it to tell the table how tall each cell is)
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        // this switch statement puts indexPath.section and indexPath.row into a tuple
        // a tuple is a list of values inside ( ) parentheses 
        // tuples are useful for returning multiple values (convenient in switch statements
        switch (indexPath.section, indexPath.row) {
            case (0, 0):
              return 88
            
            case (1, _):
              // ternary coditional operator (careful not to write 'imageView.hidden?' without the space;
              // swift will confuse this with an optional)
              return imageView.hidden ? 44 : 280
            
            case (2, 2):
                // resizes the UILabel to make all its text fit to the width of the cell
                // the frame property is a CGRect that describes the position and size of a view
                // CGRect is a struct that describes a rectangle
                addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
                
                // 'sizeToFit()' removed any spare space to the right and bottom of the label
                addressLabel.sizeToFit()
                addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
                return addressLabel.frame.size.height + 20
            
            default:
              return 44
        }
    }
    
    // this limits taps to just the cells from the first two sections
    // third section has read only labels (doesn't need to allow taps)
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?
    {
        if indexPath.section == 0 || indexPath.section == 1
        {
            return indexPath
        }
        
        else
        {
            return nil
        }
    }
    
    // called right before a cell becomes visible
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.blackColor()
        
        if let textLabel = cell.textLabel {
            textLabel.textColor = UIColor.whiteColor()
            textLabel.highlightedTextColor = textLabel.textColor
        }
        
        if let detailLabel = cell.detailTextLabel {
            detailLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
            detailLabel.highlightedTextColor = detailLabel.textColor
        }
        
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        cell.selectedBackgroundView = selectionView
        
        if indexPath.row == 2 {
            let addressLabel = cell.viewWithTag(100) as! UILabel
            addressLabel.textColor = UIColor.whiteColor()
            addressLabel.highlightedTextColor = addressLabel.textColor
        }
    }
    
    // handles actual taps on the rows
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 && indexPath.row == 0
        {
            // brings up the keyboard
            descriptionTextView.becomeFirstResponder()
        }
        
        else if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            pickPhoto()
        }
    }
    
    // adds an observer for UIApplicationDidEnterBackgroundNotification 
    // when this notification is received, NSNotificationCenter will call the closure
    // this uses "trailing" closure syntax (closure immediately follows method call)
    // if there is an active image picker or action sheet, you dismiss it (also hide keyboard if it was active)
    // closures capture variables that are used inside the closure (keeps references to them)
    // one of the issues with this is that it will contain a strong reference to 'self', so it is incredibly
    // important to make self a 'weak' reference to avoid an ownership cycle
    // [weak self] is the capture list for the closure (it tells the closure that the variable
    // self will still be captured but as a weak reference, not strong)
    // the closure will no longer keep the view controller alive 
    // weak references can become nil, which means the captured self is now an optional inside the clsoure
    // must unwrap it with if let before you can send messages to the view controller
    func listenForBackgroundNotification() {
        observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] _ in
            
            if let strongSelf = self {
                
                // image picker and the action sheet are both presented modally that lie on top of everything else
                // if such a modal view controller is active, self.presentedViewController property has a reference to
                // that modal view controller
                if strongSelf.presentedViewController != nil {
                    strongSelf.dismissViewControllerAnimated(false, completion: nil)
                }
            
                strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
}

// do this in an extension to group photo-picking functionality together
// it's convenient to place conceptually related methods into their own extension
// in order to implement the camera, you must conform to both UIImagePickerController and UINavigationController protocol
// however, you don't need to implement any of the UINavigationController delegate mtehods
extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // the UIImagePickerController is a view controller built into UIKit that takes care of the entire
    // process of taking new photos and picking them from the user's photo library
    // all you need to do is create a UIImagePickerController instance, set its properties to configure the picker,
    // set its delegate, and present it
    func takePhotoWithCamera() {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = MyImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.view.tintColor = view.tintColor
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // checks to see if the device has a camera or not
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            showPhotoMenu()
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    // each action has a closure to determine what happens when the action is selected (calls a method
    // in the extension)
    // use '_' to ignore the parameter passed to the closure (a reference to UIAlertAction)
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { _ in self.takePhotoWithCamera() })
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default,
            handler: { _ in self.choosePhotoFromLibrary() })
        alertController.addAction(chooseFromLibraryAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // gets called when the user has selected a photo in the image picker
    // 'info' is a dictionary (maps strings to AnyObjects (must cast from AnyObject to desired object))
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        // use UIImagePickerControllerEditedImage key to retrieve the UIImage object that contains the image from after the
        // move and scale operation
        // dictionaries always return optionals because there is a chance that the specified key doesn't exist in the dictionary
        // also use as? because image is an optional instance variable
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let image = image {
            showImage(image)
        }
        
        // refreshes the table view and sets the photo row to the proper height
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}