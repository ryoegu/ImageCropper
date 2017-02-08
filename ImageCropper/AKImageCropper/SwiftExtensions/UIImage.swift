//
//  UIImage.swift
//  Extension file
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 The Krachulovs. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit

extension UIImage {

    /// Crop image from self 
    ///
    /// Usage:
    ///
    ///  var img = image.getImageInRect(CGRectMake(50,50,150,150))
    
    func getImageInRect(_ rect: CGRect) -> UIImage {
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        // Sets the clipping path to the intersection of the current clipping path with the area defined by the specified rectangle.
        context?.clip(to: CGRect(origin: CGPoint.zero, size: rect.size))
        
        draw(in: CGRect(origin: CGPoint(x: -rect.origin.x, y: -rect.origin.y), size: size))
        
        // Returns an image based on the contents of the current bitmap-based graphics context.
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }
}
