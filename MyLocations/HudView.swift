//
//  HudView.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/10/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit

class HudView: UIView
{
    var text = ""
    
    // convenience constructor (always a class method -> class method works on the class as a whole)
    // use a convenient constructor when there are more steps needed than just initializing the view
    // so the caller doesn't have to worry about any of this extra work
    class func hudInView(view: UIView, animated: Bool) -> HudView
    {
        // inherited init method from UIView
        let hudView = HudView(frame: view.bounds)
        hudView.opaque = false
        
        // the view that creates an instance from this convenient constructor will be declared as
        // the parent view of this instance
        view.addSubview(hudView)
        
        // while the hud is being displayed, don't allow the user to interact with the screen anymore
        // because the done button has been tapped and is in the process of closing
        view.userInteractionEnabled = false
        
        hudView.showAnimated(animated)
        return hudView
    }
    
    // this method is invoked whenever UIKit wants your view to redraw itself
    override func drawRect(rect: CGRect)
    {
        // this code draws a filled rectangle with rounded corners in the center of the screen
        
        // when working with UIKit or Core Graphics, use CGFloat instead of Float or Double
        // in this case you must force the type of these constants to be CGFloat
        let boxWidth: CGFloat = 96
        let boxHeight: CGFloat = 96
        
        // hud rectangle is to be centered horizontally and vertically on the screen
        // the size of the screen is given by bounds.size
        // use round() to make sure the rectangle doesn't have fractional pixel boundaries (makes the image look fuzzy)
        let boxRect = CGRect(
            x: round((bounds.size.width - boxWidth) / 2),
            y: round((bounds.size.height - boxHeight) / 2),
            width: boxWidth,
            height: boxHeight)
        
        // UIBezierPath is a useful object for drawing rectangles with rounded corners
        // tell the object how large the rectangle is and how round the corners should be
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        
        // give rectangle an 80% opaque dark gray color
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        
        // loads the checkmark image into a UIImage object
        // calculates the position for that image based on the center coordinate of the HUD view
        // and the dimensions of the image
        // UIImage(named) is a 'failable initializer' (there may be no image with the specified name, 
        // or the file may contain an invalid image)
        if let image = UIImage(named: "Checkmark")
        {
            let imagePoint = CGPoint(
                x: center.x - round(image.size.width / 2),
                y: center.y - round(image.size.height / 2) - boxHeight / 8)
            
            image.drawAtPoint(imagePoint)
        }
        
        // figure out how big the text is, to figure out where to position it
        // also choose the color for the text (plain white)
        let attribs = [ NSFontAttributeName: UIFont.systemFontOfSize(16),
            NSForegroundColorAttributeName: UIColor.whiteColor() ]
        
        // calculate how wide and tall the text will be
        let textSize = text.sizeWithAttributes(attribs)
        
        // calculate where to draw the text and draw it
        let textPoint = CGPoint(
            x: center.x - round(textSize.width / 2),
            y: center.y - round(textSize.height / 2) + boxHeight / 4)
        
        text.drawAtPoint(textPoint, withAttributes: attribs)
    }
    
    // contains steps for doing UIView based animations
    func showAnimated(animated: Bool)
    {
        if animated
        {
            // set up initial state of the view before the animation starts
            // alpha is 0 to make the view fully transparent
            // (transform is set to 1.3, basically meaning the view is initially stretched out)
            alpha = 0
            transform = CGAffineTransformMakeScale(1.3, 1.3)
            
            // set up the animation (the closure describes the animation)
            // the closure is also not executed right away
            // UIKit will animate the properties inside the closure from their initial to final state
            // inside of the closure, set up the new state of the view it should have after the animation is done
            // must use 'self' inside closure to referene to HudView instance and properties (rules for closure)
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                    self.alpha = 1
                    self.transform = CGAffineTransformIdentity
                },
                completion: nil)
        }
    }
}
