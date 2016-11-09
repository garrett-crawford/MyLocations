//
//  AppDelegate.swift
//  MyLocations
//
//  Created by Garrett Crawford on 1/31/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit
import CoreData


let MyManagedObjectContextSaveDidFailNotification = "MyManagedObjectContextSaveDidFailNotification"

// defines a new global function for handling fatal Core Data errors
func fatalCoreDataError(error: ErrorType)
{
    print("*** Fatal error: \(error)")
    
    // uses NSNotificationCenter to post a notification
    NSNotificationCenter.defaultCenter().postNotificationName(MyManagedObjectContextSaveDidFailNotification, object: nil)
}


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    
    // this is the code needed to load the data model defined and to connect it to an SQlite data store
    // this is very standard that will be the same for almost any Core Data app you write
    // this code creates a lazily loaded variable 'managedObjectContext' that is an object
    // of type NSManagedObjectContext
    // this is initialized using a closure and would be invoked immediately because of () at the end of the closure,
    // however, the 'lazy' keyword means that the block in the closure isn't performed right away
    // this object won't be created until you need it (lazy loading)
    lazy var managedObjectContext: NSManagedObjectContext = {
        
        // create an NSURL object to point to the Core Data model in the folder named "DataModel.momd"
        guard let modelURL = NSBundle.mainBundle().URLForResource(
            "DataModel", withExtension: "momd") else {
                fatalError("Could not find data model in app bundle")
        }
        
        // create an NSManagedObjectModel from the previously made NSURL object
        // represents the data model during run time
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing model from: \(modelURL)")
        }
        
        // the app's data is stored in an SQLite database inside the app's Documents folder
        // here we create an NSURL object pointing at the DataStore.sqlite file
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        
        let documentsDirectory = urls[0]
        let storeURL = documentsDirectory.URLByAppendingPathComponent("DataStore.sqlite")

        
        do
        {
            // create an NSPersistentStoreCoordinator object
            // this object is in charge of the SQLite database
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            // add the SQLite database to the store coordinator
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            
            // create the NSManagedObjectContext object and return it
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            return context
            
        // print an error message and terminate the app if something goes wrong
        } catch {
            fatalError("Error adding persistent store at \(storeURL): \(error)")
        }
    }()
    
    func listenForFatalCoreDataNotifications()
    {
        // tell NSNotificationCenter to notify me when a 'MyManagedObjectContextSaveDidFailNotification' is posted
        // the actual code that is performed when that happens is in a closure following 'usingBlock:'
        NSNotificationCenter.defaultCenter().addObserverForName(MyManagedObjectContextSaveDidFailNotification, object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { notification in
          
                
          // create UIAlertController to show the error message
          let alert = UIAlertController(title: "Internal Error", message:
              "There was a fatal error in the app and it cannot continue.\n\n" +
              "Press OK to terminate the app. Sorry for the inconvenience.",
              preferredStyle: .Alert)
          
          // add an action for the alert's OK button (code for handling the button press is in a closure)
          // the '_' is called the 'wildcard' and you can use it whenever a name is expected but you don't
          // really care about it (it allows you to ignore a certain parameter)
          let action = UIAlertAction(title: "OK", style: .Default) { _ in
            let exception = NSException(name: NSInternalInconsistencyException, reason: "Fatal Core Data error", userInfo: nil)
            exception.raise()
          }
                
          alert.addAction(action)
             
          // present the alert
          self.viewControllerForShowingAlert().presentViewController(alert, animated: true, completion: nil)
                
        })
    }
    
    // to show the alert, you need a view controller that is currently visible, so this helper method finds one that is
    // can't simply use the window's rootViewController (in this app the rvc is the tab bar controller, it will be hidden
    // when the Location Details screen is open)
    func viewControllerForShowingAlert() -> UIViewController
    {
        let rootViewController = self.window!.rootViewController!
        
        if let presentedViewController = rootViewController.presentedViewController
        {
            return presentedViewController
        }
        
        else
        {
            return rootViewController
        }
    }


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool
    {
        customizeAppearance()
        
        // to get a reference to 'CurrentLocationViewController', must find the UITabBarController and look
        // in its viewControllers array
        let tabBarController = window!.rootViewController as! UITabBarController
        
        if let tabBarViewControllers = tabBarController.viewControllers
        {
            let currentLocationViewController = tabBarViewControllers[0] as! CurrentLocationViewController
            currentLocationViewController.managedObjectContext = managedObjectContext
            
            // looks up LocationsViewController in the storyboard and gives it a reference to
            // the managed object context
            let navigationController = tabBarViewControllers[1] as! UINavigationController
            let locationsViewController = navigationController.viewControllers[0] as! LocationsViewController
            locationsViewController.managedObjectContext = managedObjectContext
            
            let mapViewController = tabBarViewControllers[2] as! MapViewController
            mapViewController.managedObjectContext = managedObjectContext
        }
        
        listenForFatalCoreDataNotifications()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // changes the background color of all navigation bars and tab bars in the app to black
    func customizeAppearance() {
        UINavigationBar.appearance().barTintColor = UIColor.blackColor()
        
        UINavigationBar.appearance().titleTextAttributes = [ NSForegroundColorAttributeName: UIColor.whiteColor() ]
        UITabBar.appearance().barTintColor = UIColor.blackColor()
        
        let tintColor = UIColor(red: 255/255.0, green: 238/255.0, blue: 136/255.0, alpha: 1.0)
        UITabBar.appearance().tintColor = tintColor
    }
}

