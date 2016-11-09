//
//  Functions.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/13/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import Foundation

// imports the Grand Central Dispatch framework (GCD)
// a handy low-level library for handling asynchronous tasks
import Dispatch

// this is a free function (can be used anywhere in the code)
// second parameter is a closure (in this case a closure that takes no argument and no return value)
// the -> symbol means that the type represents a closure 
// the type for a closure generally looks like this: (parameter list) -> return type
// afterDelay passes the closure object along to dispatch_after
func afterDelay(seconds: Double, closure: () -> ())
{
    /* all of this stuff tells the app to close the Tag Location screen after 0.6 seconds */
    
    // call to dispatch_time converts the 0.6 second delay into an internal time format (measured in nanoseconds)
    // dispatch_after uses the delay to schedule the closure for some later point (after 0.6 seconds)
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    
    dispatch_after(when, dispatch_get_main_queue(), closure)
}

// creates a new global constant containing the path to the app's documents directory
// uses a closure to provide code that initializes this string
// like all globals, this is evaulated lazily the first time it is used
let applicationDocumentsDirectory: String = {
    let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
    return paths[0]
}()
