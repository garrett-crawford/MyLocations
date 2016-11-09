//
//  UIImage+Resize.swift
//  MyLocations
//
//  Created by Garrett Crawford on 3/17/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit

// you can use extensions to add new functionality to a class that you didn't write yourself
// in this case an extension is used to add extra functionality to UIImage w/o subclassing UIImage
extension UIImage {
    
    // calculates how big the image can be in order to fit inside the bounds rectangle
    // uses the "aspect fit" approach to keep the aspect ratio intact 
    // creates a new image context and draws the image into that
    func resizedImageWIthBounds(bounds: CGSize) -> UIImage {
        let horizontalRatio = bounds.width / size.width
        let veritcalRatio = bounds.height / size.height
        let ratio = min(horizontalRatio, veritcalRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0)
        drawInRect(CGRect(origin: CGPoint.zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}