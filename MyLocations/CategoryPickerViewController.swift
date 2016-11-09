//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by Garrett Crawford on 2/8/16.
//  Copyright © 2016 Noox. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController
{
    var selectedCategoryName = ""
    
    let categories = [
      "No Category",
      "Apple Store",
      "Bar",
      "Bookstore",
      "Club",
      "Grocery Store",
      "Historic Building",
      "House",
      "Icecream Vendor",
      "Landmark",
      "Park"]
    
    var selectedIndexPath = NSIndexPath()
    
    // when the screen opens it shows a checkmark next to the currently selected category
    // (this comes from the 'selectedCategoryName' property, filled in when seguing to this screen)
    //
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // compare each category name to the selected category name
        // '..<' just says that i is an int that increments from 0 to categories.count - 1
        for i in 0..<categories.count
        {
            // create new 'NSIndexPath' instance and store it in 'selectedIndexPath',
            // if they match
            if categories[i] == selectedCategoryName
            {
                selectedIndexPath = NSIndexPath(forRow: i, inSection: 0)
                break
            }
        }
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
        tableView.indicatorStyle = .White
    }
    
    // tapping a cell invokes the segue, so the cell that's tapped will contain
    // the index path with the category string to send 
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "PickedCategory"
        {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPathForCell(cell)
            {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return categories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let categoryName = categories[indexPath.row]
        
        cell.textLabel!.text = categoryName
        
        if categoryName == selectedCategoryName
        {
            cell.accessoryType = .Checkmark
        }
        
        else
        {
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        // when the user taps a row, remove the checkmark from the original row and put it in the new cell
        if indexPath.row != selectedIndexPath.row
        {
            if let newCell = tableView.cellForRowAtIndexPath(indexPath)
            {
                newCell.accessoryType = .Checkmark
            }
            
            if let oldCell = tableView.cellForRowAtIndexPath(selectedIndexPath)
            {
                oldCell.accessoryType = .None
            }
            
            selectedIndexPath = indexPath
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.blackColor()
        
        if let textLabel = cell.textLabel {
            textLabel.textColor = UIColor.whiteColor()
            textLabel.highlightedTextColor = textLabel.textColor
        }
        
        let selectionView = UIView(frame: CGRect.zero)
        selectionView.backgroundColor = UIColor(white: 1.0, alpha: 0.2)
        cell.selectedBackgroundView = selectionView
    }
}
