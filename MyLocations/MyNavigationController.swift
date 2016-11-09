//
//  MyNavigationController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 3/29/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit

// must subclass UINavigationController for the navigation controller that embeds the Tag/Edit Location screen
// because that is presented modally on top of the other screens and is not part of the Tab Bar controller hierarchy
class MyNavigationController: UINavigationController {
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}