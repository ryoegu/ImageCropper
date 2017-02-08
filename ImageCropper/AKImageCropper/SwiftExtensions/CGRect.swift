//
//  CGRect.swift
//  Extension file
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 The Krachulovs. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit

extension CGRect {
    
    /// Centers the rectangle inside another rectangle
    ///
    /// Usage:
    ///
    ///  var rect1 = CGRectMake(0, 0, 500, 300)
    ///  var rect2 = CGRectMake(0, 0, 100, 200)
    ///  rect2.centersRectIn(rect1) // {x 200 y 50 w 100 h 200}
    ///  rect2 = CGRectMake(0, 0, 800, 500)
    ///  rect2.centersRectIn(rect1) // {x -150 y -100 w 800 h 500}
    
    mutating func centersRectIn(_ rect: CGRect) {
        
        self = CGRectCenters(self, inRect: rect)
    }
}

/// Centers the rectangle inside another rectangle
///
/// Usage:
///
///  var rect1 = CGRectMake(0, 0, 500, 300)
///  var rect2 = CGRectMake(0, 0, 100, 200)
///  CGRectCenters(rect2, inRect: rect1) // {x 200 y 50 w 100 h 200}
///  rect2 = CGRectMake(0, 0, 800, 500)
///  CGRectCenters(rect2, inRect: rect1) // {x -150 y -100 w 800 h 500}

public func CGRectCenters(_ rect1: CGRect, inRect rect2: CGRect) -> CGRect {
    
    return CGRect(origin: CGPoint(x: (rect2.width - rect1.width) / 2, y: (rect2.height - rect1.height) / 2), size: rect1.size)
}

/// Get scale value to fit rectangle to another rectangle with ratio
///
/// Usage:
///
///  var rect1 = CGRectMake(0, 0, 500, 300)
///  var rect2 = CGRectMake(0, 0, 100, 200)
///  CGRectFitScale(rect1, toRect: rect2) // 0.2

public func CGRectFitScale(_ rect1: CGRect, toRect rect2: CGRect) -> CGFloat {
    
    return min(rect2.height / rect1.height, rect2.width / rect1.width)
}

/// Get scale value to fill rectangle to another rectangle with ratio
///
/// Usage:
///
///  var rect1 = CGRectMake(0, 0, 100, 200)
///  var rect2 = CGRectMake(0, 0, 500, 300)
///  CGRectFillScale(rect1, toRect: rect2) // 5

public func CGRectFillScale(_ rect1: CGRect, toRect rect2: CGRect) -> CGFloat {
    
    return max(rect2.height / rect1.height, rect2.width / rect1.width)
}

/// Method returns new rectangle origin and size if rectangle `aRect` goes out the rectangle `maxRect` with min rectangle size value `minSize`
///
/// Usage:
///
///  let aRect = CGRectMake(-20, 150, 100, 200)
///  let bRect = CGRectMake(0, 0, 500, 300)
///  let minSize = CGSizeMake(150, 150)
///  CGRectFit(aRect, toRect: bRect, minSize) // {x 0 y 150 w 150 h 150}
public func CGRectFit(_ aRect: CGRect, toRect bRect: CGRect, minSize: CGSize) -> CGRect {
    
    var rect = aRect
    
    rect.size.width = max(minSize.width, aRect.size.width)
    
    rect.origin.x = max(bRect.origin.x, aRect.origin.x)
    
    if rect.maxX > bRect.maxX {
        
        if bRect.maxX - minSize.width < rect.origin.x {
            
            rect.size.width = minSize.width
            rect.origin.x = bRect.maxX - rect.size.width
            
        } else {
            
            rect.size.width = bRect.maxX - rect.origin.x
        }
    }
    
    rect.size.height = max(minSize.height, aRect.size.height)
    
    rect.origin.y = max(bRect.origin.y, aRect.origin.y)
    
    if rect.maxY > bRect.maxY {
        
        if bRect.maxY - minSize.height < rect.origin.y {
            
            rect.size.height = minSize.height
            rect.origin.y = bRect.maxY - rect.size.height
            
        } else {
            
            rect.size.height = bRect.maxY - rect.origin.y
        }
    }
    
    return rect
}
