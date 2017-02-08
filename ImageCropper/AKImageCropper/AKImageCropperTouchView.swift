//
//  AKImageCropperTouchView.swift
//  AKImageCropper
//  GitHub: https://github.com/artemkrachulov/AKImageCropper
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//

import UIKit

// MARK: - AKImageCropperTouchViewDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

@objc protocol AKImageCropperTouchViewDelegate {
    
    @objc optional func cropRectChanged(_ rect: CGRect)
    @objc optional func blockScrollViewGestures() -> Bool
}

// MARK: - AKImageCropperTouchView
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

class AKImageCropperTouchView: UIView {
 
    // MARK: - Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

    /// Superview
    var cropperView: AKImageCropperView!
    
    /// Translation receiver (AKImageCropperScollView)
    weak var receiver: UIView!
  
    // Touch dimentions
    var fingerSize: CGFloat {
        
        return CGFloat(cropperView.fingerSize)
    }
    var fingerCornerSize: CGSize {
        
        return CGSize(width: fingerSize, height: fingerSize)
    }

    // Crop rectangles
    var cropRect: CGRect {
        
        return cropperView.cropRect
    }
    var cropRectMinSize: CGSize {
    
        return cropperView.cropRectMinSize
    }
    var cropRectBeforeMoving: CGRect!
    var cropRectMoved: CGRect!
    
    // Touches points
    var touchBeforeMoving: CGPoint!
    var touchMoved: CGPoint!
    
    // Flags
    var flagScrollViewGesture = true
    
    // Enums
    enum Edge {
        case top
        case left
        case right
        case bottom
    }
 
    enum RectPart {
        case no
        
        case topLeftCorner
        case topEdge
        case topRightCorner
        case rightEdge
        case bottomRightCorner
        case bottomEdge
        case bottomLeftCorner
        case leftEdge
    }
    
    var isCropRect: RectPart = .no
    
    // Managing the Delegate
    weak var delegate: AKImageCropperTouchViewDelegate?
    
    // MARK: - Draw view
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

    #if DEBUG
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        context?.setShouldAntialias(true)
        
        context?.setFillColor(UIColor(red: 255, green: 0, blue: 255, alpha: 0.5).cgColor)
        context?.addRect(topLeftCorner())
        context?.addRect(topRightCorner())
        context?.addRect(bottomLeftCorner())
        context?.addRect(bottomRightCorner())
        context?.fillPath()
        
        context?.setFillColor(UIColor(red: 0, green: 255, blue: 255, alpha: 0.5).cgColor)
        context?.addRect(leftEdgeRect())
        context?.addRect(rightEdgeRect())
        context?.addRect(topEdgeRect())
        context?.addRect(bottomEdgeRect())
        context?.fillPath()
    }
    #endif
    
    // MARK: - Move crop rectangle
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    func topLeftCorner() -> CGRect {
        
        return CGRect(origin: CGPoint(x: cropRect.minX, y: cropRect.minY), size: fingerCornerSize)
    }
    func topRightCorner() -> CGRect {
        
        return CGRect(origin: CGPoint(x: cropRect.maxX, y: cropRect.minY), size: fingerCornerSize)
    }
    func bottomLeftCorner() -> CGRect {
        
        return CGRect(origin: CGPoint(x: cropRect.minX, y: cropRect.maxY) , size: fingerCornerSize)
    }
    func bottomRightCorner() -> CGRect {
        
        return CGRect(origin: CGPoint(x: cropRect.maxX, y: cropRect.maxY), size: fingerCornerSize)
    }
    func topEdgeRect() -> CGRect {
        
        return CGRect(x: topLeftCorner().maxX, y: topLeftCorner().minY, width: cropRect.width - fingerSize, height: fingerSize)
    }
    func bottomEdgeRect() -> CGRect {
        
        return CGRect(x: bottomLeftCorner().maxX,  y: cropRect.maxY, width: cropRect.width - fingerSize, height: fingerSize)
    }
    func rightEdgeRect() -> CGRect {
        
        return CGRect(x: topRightCorner().minX, y: topRightCorner().maxY, width: fingerSize, height: cropRect.height - fingerSize)
    }
    func leftEdgeRect() -> CGRect {
        
        return CGRect(x: topLeftCorner().minX, y: topLeftCorner().maxY, width: fingerSize, height: cropRect.height - fingerSize)
    }
    
    func isCropRect (_ point: CGPoint) -> RectPart {
        
        if topEdgeRect().contains(point) {
            
            return .topEdge
            
        } else if bottomEdgeRect().contains(point) {
            
            return .bottomEdge
            
        } else if rightEdgeRect().contains(point) {
            
            return .rightEdge
            
        } else if leftEdgeRect().contains(point) {
            
            return .leftEdge
            
        } else if topLeftCorner().contains(point) {
            
            return .topLeftCorner
            
        } else if topRightCorner().contains(point) {
            
            return .topRightCorner
            
        } else if bottomLeftCorner().contains(point) {
            
            return .bottomLeftCorner
            
        } else if bottomRightCorner().contains(point) {
            
            return .bottomRightCorner
        }
        
        return .no
    }

    func moveRect(_ part: RectPart, onTranslation translation: CGPoint) {
        
        // copy
        cropRectMoved = cropRect
        
        switch part {
            case .topLeftCorner:
                
                moveEdge(.top, onDistance: translation.y)
                moveEdge(.left, onDistance: translation.x)
            
            case .topEdge:
                
                moveEdge(.top, onDistance: translation.y)
            
            case .topRightCorner:
                
                moveEdge(.top, onDistance: translation.y)
                moveEdge(.right, onDistance: translation.x)
            
            case .rightEdge:
                
                moveEdge(.right, onDistance: translation.x)

            case .bottomRightCorner:
                
                moveEdge(.bottom, onDistance: translation.y)
                moveEdge(.right, onDistance: translation.x)
            
            case .bottomEdge:
                
                moveEdge(.bottom, onDistance: translation.y)
            
            case .bottomLeftCorner:
                
                moveEdge(.bottom, onDistance: translation.y)
                moveEdge(.left, onDistance: translation.x)
            
            case .leftEdge:
                
                moveEdge(.left, onDistance: translation.x)
            
            default: ()
        }
        
        cropperView.setCropRect(cropRectMoved)
    }
    
    func moveEdge(_ edge: Edge, onDistance distance: CGFloat) {
        
        switch edge {
            case .top :
                
                // Update sizes
                cropRectMoved.origin.y += distance
                cropRectMoved.size.height -= distance
                
                // Save point if moved touch over touch view
                /// First touched point in top edge
                let pointInEdge = touchBeforeMoving.y - cropRectBeforeMoving.minY
                
                /// Min point if crop rectangle edge will move up
                let minStickPoint = pointInEdge
                
                /// Max point if crop rectangle edge will move down
                let maxStickPoint = cropRectBeforeMoving.maxY - cropRectMinSize.height + pointInEdge
            
                // Process
                if touchMoved.y < minStickPoint || cropRectMoved.minY < frame.minY {
    
                    cropRectMoved.origin.y = 0
                    cropRectMoved.size.height = cropRectBeforeMoving.maxY
                }
                if  touchMoved.y > maxStickPoint || cropRectMoved.height < cropRectMinSize.height {
                    
                    cropRectMoved.origin.y = cropRectBeforeMoving.maxY - cropRectMinSize.height
                    cropRectMoved.size.height = cropRectMinSize.height
                }
            
            case .right :
                
                // Update size
                cropRectMoved.size.width += distance
                
                // Save point if moved touch over touch view
                /// First touched point in bottom edge
                let pointInEdge = abs(cropRectBeforeMoving.maxX - touchBeforeMoving.x)
                
                let maxFrameX = frame.maxX - rightEdgeRect().size.width
                
                /// Min point if crop rectangle edge will move up
                let minStickPoint = cropRectBeforeMoving.minX + pointInEdge + cropRectMinSize.width
                
                /// Max point if crop rectangle edge will move down
                let maxStickPoint = maxFrameX + pointInEdge
                
                if  touchMoved.x > maxStickPoint || cropRectMoved.maxX > maxFrameX {
                    
                    cropRectMoved.size.width = maxFrameX - cropRectMoved.origin.x
                }
                if touchMoved.x < minStickPoint || cropRectMoved.width < cropRectMinSize.width {
                    
                    cropRectMoved.size.width = cropRectMinSize.width
                }
            
            case .bottom :
                
                // Update size
                cropRectMoved.size.height += distance
            
                // Save point if moved touch over touch view
                /// First touched point in bottom edge
                let pointInEdge = abs(cropRectBeforeMoving.maxY - touchBeforeMoving.y)
     
                let maxFrameY = frame.maxY - bottomEdgeRect().size.height
                
                /// Min point if crop rectangle edge will move left
                let minStickPoint = cropRectBeforeMoving.minY + pointInEdge + cropRectMinSize.height
                
                /// Max point if crop rectangle edge will move right
                let maxStickPoint = maxFrameY + pointInEdge
                
                if  touchMoved.y > maxStickPoint || cropRectMoved.maxY > maxFrameY {
                        
                    cropRectMoved.size.height = maxFrameY - cropRectMoved.origin.y
                }
                if touchMoved.y < minStickPoint || cropRectMoved.height < cropRectMinSize.height {
                    
                    cropRectMoved.size.height = cropRectMinSize.height
                }
            case .left :
                
                // Update sizes
                cropRectMoved.origin.x += distance
                cropRectMoved.size.width -= distance
            
                // Save point if moved touch over touch view
                /// First touched point in top edge
                let pointInEdge = touchBeforeMoving.x - cropRectBeforeMoving.minX
                
                /// Min point if crop rectangle edge will move left
                let minStickPoint = pointInEdge
                
                /// Max point if crop rectangle edge will move right
                let maxStickPoint = cropRectBeforeMoving.maxX - cropRectMinSize.width + pointInEdge
                
                // Process
                if touchMoved.x < minStickPoint || cropRectMoved.minX < frame.minX {
                    
                    cropRectMoved.origin.x = 0
                    cropRectMoved.size.width = cropRectBeforeMoving.maxX
                }
                if  touchMoved.x > maxStickPoint || cropRectMoved.width < cropRectMinSize.width {
                    
                    cropRectMoved.origin.x = cropRectBeforeMoving.maxX - cropRectMinSize.width
                    cropRectMoved.size.width = cropRectMinSize.width
                }
        }
       
        // Another test crop rectangle sizes
        cropRectMoved.origin.y = max(0, cropRectMoved.origin.y)
        cropRectMoved.origin.y = min(cropRectMoved.origin.y, cropRectBeforeMoving.maxY - bottomEdgeRect().size.height)
        
        cropRectMoved.size.height = max(cropRectMinSize.height, cropRectMoved.size.height)
        cropRectMoved.size.height = min(frame.height - fingerSize, cropRectMoved.size.height)
        
        cropRectMoved.origin.x = max(0, cropRectMoved.origin.x)
        cropRectMoved.origin.x = min(cropRectMoved.origin.x, cropRectBeforeMoving.maxX - rightEdgeRect().size.width)
        
        cropRectMoved.size.width = max(cropRectMinSize.width, cropRectMoved.size.width)
        cropRectMoved.size.width = min(frame.width - fingerSize, cropRectMoved.size.width)
    }
}

// MARK: - Translation
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperTouchView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            
        if (self.point(inside: point, with: event)) {
            
            if isCropRect(point) != .no {
                
                flagScrollViewGesture = false
                
                return self
            }

            return receiver
        }
        
        return nil
    }
}


// MARK: - Touches
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperTouchView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            touchBeforeMoving = touch.location(in: self)
            
            cropRectBeforeMoving = cropRect
            
            isCropRect = isCropRect(touchBeforeMoving)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first {
            
            touchMoved = touch.location(in: self)
            
            let prevTouchMoved = touch.previousLocation(in: self)
            
            if isCropRect != .no {
                
                moveRect(isCropRect, onTranslation: CGPoint(x: touchMoved.x - prevTouchMoved.x, y: touchMoved.y - prevTouchMoved.y))
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Reset
        touchBeforeMoving = nil
        cropRectBeforeMoving = nil
        isCropRect = .no
        
        flagScrollViewGesture = true
    }
}
