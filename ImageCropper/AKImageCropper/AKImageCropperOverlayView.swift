//
//  AKImageCropperOverlayView.swift
//  AKImageCropper
//  GitHub: https://github.com/artemkrachulov/AKImageCropper
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit

class AKImageCropperOverlayView: UIView {

    // MARK: - Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    /// Superview
    var croppperView: AKImageCropperView!
    
    // Corners
    var cornerOffset: CGFloat {
        
        return CGFloat(croppperView.cornerOffset)
    }
    var cornerSize: CGSize {
        
        return croppperView.cornerSize
    }

    // MARK: - Draw
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let cropRect = croppperView.cropRect.offsetBy(dx: cornerOffset, dy: cornerOffset)
        
        // Get the Graphics Context
        let context = UIGraphicsGetCurrentContext()
        
        // Draw background
        // Source: Self
        overlayViewDrawBg(rect)
        
        context?.saveGState()
     
        // Draw crop stroke
        // Source: AKImageCropperViewDelegate
        croppperView.overlayViewDrawStrokeInCropRect(cropRect)
        
        context?.clear(cropRect)
        context?.saveGState()
        
        // Draw grig stroke
        // Source: AKImageCropperViewDelegate
        if croppperView.grid {
            
            croppperView.overlayViewDrawGridInCropRect(cropRect)
            context?.saveGState()
        }

        // Draw corners
        // Source: AKImageCropperViewDelegate
        
        let topLeftPoint = CGPoint(x: cropRect.minX - cornerOffset, y: cropRect.minY - cornerOffset)
        croppperView.overlayViewDrawInTopLeftCropRectCornerPoint(topLeftPoint)
        
        let topRightPoint = CGPoint(x: cropRect.maxX + cornerOffset - cornerSize.width, y: cropRect.minY - cornerOffset)
        croppperView.overlayViewDrawInTopRightCropRectCornerPoint(topRightPoint)
        
        let bottomRightPoint = CGPoint(x: cropRect.maxX - cornerSize.width + cornerOffset, y: cropRect.maxY - cornerSize.height + cornerOffset)
        croppperView.overlayViewDrawInBottomRightCropRectCornerPoint(bottomRightPoint)
        
        let bottomLeftPoint = CGPoint(x: cropRect.minX - cornerOffset, y: cropRect.maxY  - cornerSize.height + cornerOffset)
        croppperView.overlayViewDrawInBottomLeftCropRectCornerPoint(bottomLeftPoint)

        context?.saveGState()
    }
    
    func overlayViewDrawBg(_ rect: CGRect) {
        
        // Background Color
        croppperView.overlayColor.setFill()
        
        // Draw
        let path = UIBezierPath(rect: rect.insetBy(dx: cornerOffset, dy: cornerOffset))
            path.fill()        
    }
}
