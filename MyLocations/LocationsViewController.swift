//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/29/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController
{
    var managedObjectContext: NSManagedObjectContext!
    
    // lazy initialization with a closure to set everything up
    // good habit to lazily load objects because you don't allocate them until you first use them
    // this makes the app quicker to start and saves memory
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        // the object that describes which objects you're going to fetch from the data store
        // to retrive an object that you previously saved to the data store, you create a fetch request
        // that describes the search parameters of the object/s that you're looking for
        let fetchRequest = NSFetchRequest()
        
        // the 'NSEntityDescription' instance tells the fetch request you're looking for Location entities
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        
        // 'NSSortDescriptor' tells the fetch request to sort on the date attribute, in ascending order
        let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
        
        // allows you to tweak how many objects will be fetched at a time
        fetchRequest.fetchBatchSize = 20
        
        // the cacheName needs to be a unique name that NSFetchedResultsController uses to cache the search results
        // the cache is kept around even after the app quits, so the next time the fetch request is super fast
        // the fetchedResultsController will group the search results based on the value of the category attribute
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // makes the view have an edit button to delete rows
        navigationItem.rightBarButtonItem = editButtonItem()
        performFetch()
        
        // makes the table view black
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
    }
    
    func performFetch()
    {
        do
        {
            try fetchedResultsController.performFetch()
        } catch {
            fatalCoreDataError(error)
        }
    }
    
    // invoked when this view controller is destroyed
    // defensive programming to nil out the delegate property so that no more notifications are received that are still pending
    deinit
    {
        fetchedResultsController.delegate = nil
    }
    
    // MARK: - UITableViewDelegate
    
    // this is a UITableViewDelegate method
    // it gets called once for each section in the table view
    // here you create a label for the section name, a 1-pixel high view that functions as a separator line,
    // and a container view to hold these two subviews
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let labelRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 14, width: 300, height: 14)
        
        let label = UILabel(frame: labelRect)
        label.font = UIFont.boldSystemFontOfSize(11)
        
        label.text = tableView.dataSource!.tableView!(tableView, titleForHeaderInSection: section)
        
        label.textColor = UIColor(white: 1.0, alpha: 0.4)
        label.backgroundColor = UIColor.clearColor()
        
        let separatorRect = CGRect(x: 15, y: tableView.sectionHeaderHeight - 0.5,
                                   width: tableView.bounds.size.width - 15, height: 0.5)
        let separator = UIView(frame: separatorRect)
        separator.backgroundColor = tableView.separatorColor
        
        let viewRect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.sectionHeaderHeight)
        
        let view = UIView(frame: viewRect)
        view.backgroundColor = UIColor(white: 0, alpha: 0.85)
        view.addSubview(label)
        view.addSubview(separator)
        return view
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // the sections property returns an array of NSFetchedResultsSectionInfo objects that describe
        // each section of the table view (number of rows is found in the numberOfObjects property)
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationCell", forIndexPath: indexPath) as! LocationCell
        
        let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
        
        cell.configureForLocation(location)
        
        return cell
    }
    
    // gets the location object from the selected row and removes it from the managedObjectContext
    // triggers the NSFetchedResultsController to send a notification to the delegate (NSFetchedResultsChangeDelete),
    // which then removes the corresponding entry from the table
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
            
            location.removePhotoFile()
            managedObjectContext.deleteObject(location)
            
            do {
                try managedObjectContext.save()
            } catch {
                fatalCoreDataError(error)
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name.uppercaseString
    }
    
    // invoked when user taps a row in the Locations screen
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditLocation"
        {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            controller.managedObjectContext = managedObjectContext
            
            if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell)
            {
                let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
                controller.locationToEdit = location
            }
        }
    }
}

// the methods inside of this extension are fairly standard and will be mostly the same for other apps
// these methods will be invoked when certain objects were inserted, remove, or updated
// in response, you call the corresponding methods on UITableView to update, insert, or remove rows
extension LocationsViewController: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("*** controllerWillChangeContent")
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            print("*** NSFetchedResultsChangeInsert (object)")
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            
        case .Delete:
            print("*** NSFetchedResultsChangeDelete (object)")
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            
        case .Update:
            print("*** NSFetchedResultsChangeUpdate (object)")
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? LocationCell {
                let location = controller.objectAtIndexPath(indexPath!) as! Location
                cell.configureForLocation(location)
            }
            
        case .Move:
            print("*** NSFetchedResultsChangeMove (object)")
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            print("*** NSFetchedResultsChangeInsert (section)")
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        
        
        case .Delete:
            print("*** NSFetchedResultsChangeDelete (section)")
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            
        case .Update:
            print("*** NSFetchedResultsChangeUpdate (section)")
            
        case .Move:
            print("*** NSFetchedResultsChangeMove (section)")
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("*** controllerDidChangeContent")
        tableView.endUpdates()
    }
}
