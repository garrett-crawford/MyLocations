//
//  LocationCell.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/29/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell
{
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // every object in storyboard has the awakeFromNib() method
        // it's invoked when UIKit loads the object from the storyboard
        // it's the ideal place to customize its looks
        backgroundColor = UIColor.blackColor()
        descriptionLabel.textColor = UIColor.whiteColor()
        descriptionLabel.highlightedTextColor = descriptionLabel.textColor
        addressLabel.textColor = UIColor(white: 1.0, alpha: 0.4)
        addressLabel.highlightedTextColor = addressLabel.textColor
        
        // creates a new UIView with a dark gray color
        // this new view is placed on top of the cell's background when the user taps
        // on the cell
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        selectedBackgroundView = selectionView
        
        // gives the image view rounded corners with a radius that is equal to half the width of the image
        // (makes a perfect circle)
        photoImageView.layer.cornerRadius = photoImageView.bounds.size.width / 2
        photoImageView.clipsToBounds = true
        separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureForLocation(location: Location)
    {
        if location.locationDescription.isEmpty
        {
            descriptionLabel.text = "(No Description)"
        }
        
        else
        {
            descriptionLabel.text = location.locationDescription
        }
        
        if let placemark = location.placemark
        {
            var text = ""
            text.addText(placemark.subThoroughfare)
            text.addText(placemark.thoroughfare, withSeparator: " ")
            text.addText(placemark.locality, withSeparator: ", ")
            addressLabel.text = text
            photoImageView.image = imageForLocation(location)
        }
        
        else
        {
            addressLabel.text = String(format: "Lat: %.8f, Long: %.8f", location.latitude, location.longitude)
        }
    }
    
    // returns either the image from the Location or an empty placeholder image
    func imageForLocation(location: Location) -> UIImage {
        if location.hasPhoto, let image = location.photoImage {
            return image.resizedImageWIthBounds(CGSize(width: 52, height: 52))
        }
        
        // UIImage(named) is a failable initializer, so it returns an optional
        return UIImage(named: "No Photo")!
    }

}
