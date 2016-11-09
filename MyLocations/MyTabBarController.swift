//
//  MyTabBarController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 3/29/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit

// subclass UITabBarController to customize the status bar
class MyTabBarController: UITabBarController {
    
    // customize style here
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // by returning nil from this method, the tab bar controller will look at its
    // own 'preferredStatusBarStyle()' method
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return nil
    }
}
