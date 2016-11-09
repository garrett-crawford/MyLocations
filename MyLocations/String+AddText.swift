//
//  String+AddText.swift
//  MyLocations
//
//  Created by Garrett Crawford on 3/19/16.
//  Copyright © 2016 Noox. All rights reserved.
//

extension String {
    
    // this method always modifies the string object that it belongs to (adds text and separator to self)
    // when a method changes the value of a struct, it must be marked as mutating
    // String is a struct, which is a value type (can't be modified when declared with let)
    // mutating tells Swift that addText(withSeparator) can only be used on strings that are made with var,
    // but not strings made with let
    // don't need to use mutating with methods inside a class because classes are reference types
    // also an example of a default parameter (allows caller to leave out this parameter when calling the method)
    mutating func addText(text: String?, withSeparator separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
