//
//  AKImageCropperView.swift
//  AKImageCropper
//  GitHub: https://github.com/artemkrachulov/AKImageCropper
//
//  Created by Krachulov Artem
//  Copyright (c) 2015 Krachulov Artem. All rights reserved.
//  Website: http://www.artemkrachulov.com/
//
// Hierarchy
//
//  - - - AKImageCropperView - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// |                                                                                               |
// |   - - - Aspect View - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   |
// |  |                                                                                         |  |
// |  |   - - - Touch View - - -    - - - Overlay View - - -    - - - Scroll View - - - - - -   |  |
// |  |  |                      |  |                        |  |                             |  |  |
// |  |  |                      |  |                        |  |   - - - Image View - - -    |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  |                       |  |  |  |
// |  |  |                      |  |                        |  |  | _ _ _ _ _ _ _ _ _ _ _ |  |  |  |
// |  |  | _ _ _ _ _ _ _ _ _ _ _|  | _ _ _ _ _ _ _ _ _ _ _ _|  | _ _ _ _ _ _ _ _ _ _ _ _ _ _ |  |  |
// |  | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |  |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ |


import UIKit

// MARK: - AKImageCropperViewDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

@objc protocol AKImageCropperViewDelegate {
    
    // Any crop rect changes
    @objc optional func cropRectChanged(_ rect: CGRect)
    
    // Custom overlay view
    @objc optional func overlayViewDrawInTopLeftCropRectCornerPoint(_ point: CGPoint)
    @objc optional func overlayViewDrawInTopRightCropRectCornerPoint(_ point: CGPoint)
    @objc optional func overlayViewDrawInBottomRightCropRectCornerPoint(_ point: CGPoint)
    @objc optional func overlayViewDrawInBottomLeftCropRectCornerPoint(_ point: CGPoint)
    @objc optional func overlayViewDrawStrokeInCropRect(_ cropRect: CGRect)
    @objc optional func overlayViewDrawGridInCropRect(_ cropRect: CGRect)
}

// MARK: - AKImageCropperView
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

class AKImageCropperView: UIView {

    // MARK: - Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    var image: UIImage! {
        get {
            
            return flagCreated ? imageView.image : nil
        }
        set(image) {
            
            if image != nil {
                
                // Scroll View
                scrollView.contentSize = image.size
                
                // Image View
                imageView.image = image
                imageView.frame.size = image.size
                
                // Update Sizes
                refresh()
            }
        }
    }

    var cropRect: CGRect  {

        return cropRectSaved ?? CGRect(origin: CGPoint.zero, size: scrollView.frame.size)
    }
    var cropRectTranslatedToImage: CGRect {
        
        return overlayViewIsActive ?
            CGRect(x: (scrollView.contentOffset.x + cropRect.origin.x) / scrollView.zoomScale, y: (scrollView.contentOffset.y + cropRect.origin.y) / scrollView.zoomScale, width: cropRect.size.width / scrollView.zoomScale, height: cropRect.size.height / scrollView.zoomScale) :
            CGRect(x: scrollView.contentOffset.x / scrollView.zoomScale, y: scrollView.contentOffset.y / scrollView.zoomScale, width: scrollView.frame.size.width / scrollView.zoomScale, height: scrollView.frame.size.height / scrollView.zoomScale)
    }
    
    var cropRectMinSize = CGSize(width: 30, height: 30)
    
    fileprivate (set) var overlayViewIsActive = false
    
    // Managing the Delegate
    weak var delegate: AKImageCropperViewDelegate?
    
    // MARK: - Configuration
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    var overlayViewAnimationDuration: TimeInterval = 0.3
    var overlayViewAnimationOptions: UIViewAnimationOptions = .curveEaseOut
    
    var fingerSize = 30 // px
    
    var cornerOffset = 3 // px
    var cornerSize = CGSize(width: 18, height: 18)
    
    var grid = true
    var gridLines = 2
    
    var overlayColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    var strokeColor = UIColor.white
    var cornerColor = UIColor.white
    var gridColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
    
    // MARK: - Class Properties
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    fileprivate var aspectView: UIView!
    fileprivate var touchView: AKImageCropperTouchView!
    fileprivate var overlayView: AKImageCropperOverlayView!
    fileprivate var overlayViewCornerOffset: CGFloat {
        
        return CGFloat(cornerOffset)
    }
    fileprivate (set) var scrollView: AKImageCropperScollView!
    fileprivate var scrollViewActiveOffset: CGFloat {
        
        return overlayViewIsActive ? CGFloat(fingerSize) / 2 : 0
    }
    fileprivate var scrollViewOffset: CGFloat {
        
        return CGFloat(fingerSize / 2)
    }
    fileprivate (set) var imageView: UIImageView!
    
    // Saved crop rect (if rectagle was set in code)
    fileprivate var cropRectSaved: CGRect!
    
    // MARK: - Flags
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    /// Blocks any actions if all views not initialized
    fileprivate var flagCreated = false
    
    /// Blocks new action until the current not finish
    fileprivate var flagOverlayAnimation = false
    
    /// Blocks transition when using built-in transition
    fileprivate var flagCropperViewTransitionWithAnimation = true
    
    /// Blocks multiple refreshing if size is same
    fileprivate var flagRefresh = true
    
    // MARK: - Initialization
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    init(frame: CGRect, image: UIImage, showOverlayView: Bool) {
        super.init(frame: frame)
        
        create(image, showOverlayView: showOverlayView)
    }
    
    init(image: UIImage, showOverlayView: Bool) {
        super.init(frame:CGRect.zero)
        
        create(image, showOverlayView: showOverlayView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        create(nil, showOverlayView: false)
    }
    
    
    fileprivate func create(_ image: UIImage!, showOverlayView: Bool) {
        if !flagCreated {
            
            backgroundColor = UIColor.clear
            
            // Aspect View
            aspectView = UIView()
            aspectView.backgroundColor = UIColor.clear
            aspectView.clipsToBounds = false
            
            addSubview(aspectView)
            
            // Scroll View
            scrollView = AKImageCropperScollView()
            scrollView.backgroundColor = UIColor.clear
            scrollView.delegate = self
            scrollView.clipsToBounds = true
            scrollView.maximumZoomScale = 2
            
            aspectView.addSubview(scrollView)
            
            // Image View
            imageView = UIImageView()
            imageView.backgroundColor = UIColor.clear
            imageView.isUserInteractionEnabled = true
            scrollView.addSubview(imageView)
            
            // Overlay View
            overlayView = AKImageCropperOverlayView()
            overlayView.backgroundColor = UIColor.clear
            overlayView.isHidden = true
            overlayView.alpha = 0
            overlayView.clipsToBounds = false
            overlayView.croppperView = self
            aspectView.addSubview(overlayView)
            
            // Touch View
            touchView = AKImageCropperTouchView()
            touchView.backgroundColor = UIColor.clear
            touchView.delegate = self
            touchView.cropperView = self
            
            touchView.receiver = scrollView
            scrollView.sender = touchView
            aspectView.addSubview(touchView)
            
            // Update flag
            flagCreated = true
            
            self.image = image
            
            if showOverlayView {
                
                showOverlayViewAnimated(false, withCropFrame: nil, completion: nil)
            }
        }
    }
    
    func refresh() {
        
        let views = getViews()
        
        if flagRefresh ? aspectView.frame != views.aspect || scrollView.frame != views.scroll : false {
        
            #if DEBUG
            print("AKImageCropperView: refresh()")
            print("Aspect View Frame: \(aspectView.frame)")
            print("New Aspect View Frame: \(views.aspect)")
                
            print("Scale View Frame: \(scrollView.frame)")
            print("New Scale View Frame: \(views.scroll)")
            print("Crop Rect: \(cropRect)")
            print("Crop Rect Saved: \(cropRectSaved)")
            print(" ")
            #endif
        
            // Aspect View
            aspectView.frame = views.aspect
            
            let maxRect = CGRect(origin: CGPoint.zero, size: scrollView.frame.size)
            let minRect = cropRectMinSize
            
            let newCropRect  = CGRectFit(cropRect, toRect: maxRect, minSize: minRect)
            
            if newCropRect != cropRect && cropRectSaved != nil {
            
                cropRectSaved = newCropRect
                
                delegate?.cropRectChanged!(newCropRect)
            }
            
            // Touch View
            touchView.frame = (views.scroll).insetBy(dx: -scrollViewOffset, dy: -scrollViewOffset)
            touchView.setNeedsDisplay()
            
            // Overlay View
            overlayView.frame = (views.scroll).insetBy(dx: -overlayViewCornerOffset, dy: -overlayViewCornerOffset)
            overlayView.setNeedsDisplay()
     
            // Scroll View
            scrollView.frame = views.scroll
            scrollView.minimumZoomScale = views.scale
            scrollView.zoomScale = views.scale
        }
    }
    
    func destroy() {
        
        removeFromSuperview()
    }
    
    // MARK: - Overlay View with Crop Rect
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    func setCropRect(_ rect: CGRect) {
        
        if overlayViewIsActive {
        
            let maxRect = CGRect(origin: CGPoint.zero, size: scrollView.frame.size)
            let minRect = cropRectMinSize
            
            cropRectSaved = CGRectFit(rect, toRect: maxRect, minSize: minRect)
            
            touchView.setNeedsDisplay()
            overlayView.setNeedsDisplay()
            
            delegate?.cropRectChanged!(rect)
        }
    }
    
    func showOverlayViewAnimated(_ flag: Bool, withCropFrame rect: CGRect!, completion: (() -> Void)?) {
        if !flagOverlayAnimation  {
            
            overlayViewIsActive = true
            
            // Set new flags
            flagOverlayAnimation = true
            flagCropperViewTransitionWithAnimation = flag
            
            // Reset crop rectangle
            cropRectSaved = nil
            
            // Set new crop rectangle
            if rect != nil {
                
                setCropRect(rect)
            }
            
            viewWillTransition { () -> Void in
                
                self.overlayView.isHidden = false
                
                // Animate
                if flag {
                                        
                    UIView.animate(withDuration: self.overlayViewAnimationDuration,
                        animations: { () -> Void in
                            
                            self.overlayView.alpha = 1
                        }
                    )
                } else {
                    
                    self.overlayView.alpha = 1
                }
                
                // Reset Flags
                self.flagOverlayAnimation = false
                self.flagCropperViewTransitionWithAnimation = true
                
                // Return handler
                if completion != nil {
                    
                    completion!()
                }
            }
        }
    }
    
    func dismissOverlayViewAnimated(_ flag: Bool, completion: (() -> Void)?) {
        if !flagOverlayAnimation  {

            overlayViewIsActive = false
            
            // Set new flags
            flagOverlayAnimation = true
            flagCropperViewTransitionWithAnimation = flag
            flagRefresh = false
            
            if flag {
                UIView.animate(withDuration: overlayViewAnimationDuration,
                    animations: { () -> Void in
                        
                        self.overlayView.alpha = 0
                    }, completion: { (done) -> Void in
                    
                    self.viewWillTransition(self.dismissOverlayViewAnimatedHandler(completion))
                }
                ) 
            } else {
                
                viewWillTransition(dismissOverlayViewAnimatedHandler(completion))
            }
        }
    }

    fileprivate func dismissOverlayViewAnimatedHandler(_ completion: (() -> Void)?) -> (() -> Void)? {
    
        // Reset Flags
        flagCropperViewTransitionWithAnimation = true
        flagOverlayAnimation = false
        flagRefresh = true
        
        // Reset crop rectangle
        cropRectSaved = nil
        
        // Return handler
        return completion
    }
    
    func croppedImage() -> UIImage {
        
        let imageRect = cropRectTranslatedToImage
        
        let rect = CGRect(x: CGFloat(Int(imageRect.origin.x)), y: CGFloat(Int(imageRect.origin.y)), width: CGFloat(Int(imageRect.size.width)), height: CGFloat(Int(imageRect.size.height)))

        return image.getImageInRect(rect)
    }

    // MARK: - Helper Methods
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    fileprivate func getViews() -> (aspect: CGRect, scroll: CGRect, scale: CGFloat) {
        
        // Update Layouts
        layoutIfNeeded()
        
        if let image = image {
            
            // Crop view with offset
            let viewWithOffset = frame.insetBy(dx: scrollViewActiveOffset, dy: scrollViewActiveOffset)
            
            var scale = CGRectFitScale(CGRect(origin: CGPoint.zero, size: image.size), toRect: viewWithOffset)
                scale = scale < 1 ? scale : 1
        
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            // Scale image with proportion
            let aspectSize = CGSize(width: scaledSize.width + scrollViewActiveOffset*2, height: scaledSize.height + scrollViewActiveOffset*2)
            
            let aspect = CGRectCenters(CGRect(origin: CGPoint.zero, size: aspectSize), inRect: self.frame)
            
            var scroll = CGRect(origin: CGPoint.zero, size: aspectSize)
            
            scroll.insetBy(dx: scrollViewActiveOffset, dy: scrollViewActiveOffset)
            
            
            return (CGRect(x: ceil(aspect.minX,multiplier: 0.5), y: ceil(aspect.minY,multiplier: 0.5), width: ceil(aspect.width,multiplier: 0.5), height: ceil(aspect.height,multiplier: 0.5)), CGRect(x: ceil(scroll.minX,multiplier: 0.5), y: ceil(scroll.minY,multiplier: 0.5), width: ceil(scroll.width,multiplier: 0.5), height: ceil(scroll.height,multiplier: 0.5)), scale)
            
        } else {
            
            return (aspect: CGRect.zero, scroll: CGRect.zero, scale: 0)
        }
    }
    
    // MARK: - Rotate Animation
    //         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
    
    fileprivate func viewWillTransition(_ completion:(() -> Void)?) {
        
        if (frame.width - scrollViewActiveOffset > aspectView.frame.width && frame.height - scrollViewActiveOffset > aspectView.frame.height) || flagCropperViewTransitionWithAnimation == false {

            refresh()

            if completion != nil {
                
                completion!()
            }
            
        } else {
            
            #if DEBUG
            print("Animation viewWillTransition")
            #endif
            
            UIView.animate(withDuration: overlayViewAnimationDuration, delay: 0.0, options: overlayViewAnimationOptions,
                animations: {
                    
                    self.refresh()
                },
                completion: { (finished) -> Void in

                    if completion != nil {
                        
                        completion!()
                    }
                }
            )
        }
    }
}

// MARK: - UIScrollViewDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperView: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return imageView
    }
}

// MARK: - AKImageCropperViewDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperView: AKImageCropperViewDelegate {
    
    func overlayViewDrawInTopLeftCropRectCornerPoint(_ point: CGPoint) {

         // Prepare Rects
        let rect = CGRect(origin: point, size: cornerSize)
        let substract = CGRect(origin: CGPoint(x: point.x + overlayViewCornerOffset, y: point.y + overlayViewCornerOffset), size: CGSize(width: cornerSize.width - overlayViewCornerOffset, height: cornerSize.height - overlayViewCornerOffset))
        
        // Corner color
        cornerColor.setFill()
        
        // Draw
        let path = UIBezierPath(rect: rect)
            path.append(UIBezierPath(rect: substract).reversing())
            path.fill()
    }
    
    func overlayViewDrawInTopRightCropRectCornerPoint(_ point: CGPoint) {
        
        // Prepare Rects
        let rect = CGRect(origin: point, size: cornerSize)
        let substract = CGRect(origin: CGPoint(x: point.x, y: point.y + overlayViewCornerOffset), size: CGSize(width: cornerSize.width - overlayViewCornerOffset, height: cornerSize.height - overlayViewCornerOffset))
        
        // Corner color
        cornerColor.setFill()
        
        // Draw
        let path = UIBezierPath(rect: rect)
            path.append(UIBezierPath(rect: substract).reversing())
            path.fill()
    }
    
    func overlayViewDrawInBottomRightCropRectCornerPoint(_ point: CGPoint) {
        
        // Prepare Rects
        let rect = CGRect(origin: point, size: cornerSize)
        let substract = CGRect(origin: CGPoint(x: point.x, y: point.y), size: CGSize(width: cornerSize.width - overlayViewCornerOffset, height: cornerSize.height - overlayViewCornerOffset))
        
        // Corner color
        cornerColor.setFill()
        
        // Draw
        let path = UIBezierPath(rect: rect)
            path.append(UIBezierPath(rect: substract).reversing())
            path.fill()
    }
    
    func overlayViewDrawInBottomLeftCropRectCornerPoint(_ point: CGPoint) {
        
        // Prepare Rects
        let rect = CGRect(origin: point, size: cornerSize)
        let substract = CGRect(origin: CGPoint(x: point.x + overlayViewCornerOffset, y: point.y), size: CGSize(width: cornerSize.width - overlayViewCornerOffset, height: cornerSize.height - overlayViewCornerOffset))
        
        // Corner color
        cornerColor.setFill()
        
        // Draw
        let path = UIBezierPath(rect: rect)
            path.append(UIBezierPath(rect: substract).reversing())
            path.fill()
    }
    
    func overlayViewDrawStrokeInCropRect(_ cropRect: CGRect) {
     
        // Stroke color
        strokeColor.set()
        
        // Draw
        let path = UIBezierPath(rect: cropRect)
            path.lineWidth = 1
            path.stroke()
    }
    
    func overlayViewDrawGridInCropRect(_ cropRect: CGRect) {
        
        // Grid color
        gridColor.set()
        
        // Draw
        let path = UIBezierPath()
            path.lineWidth = 1
        
        // Vetical lines
        for i in 1...gridLines {
            
           let from = CGPoint(x: cropRect.minX + cropRect.width / (CGFloat(gridLines) + 1) * CGFloat(i), y: cropRect.minY)
            
            path.move(to: from)
            path.addLine(to: CGPoint(x: from.x, y: cropRect.maxY))
        }
        
        // Horizontal Lines
        for i in 1...gridLines {
            
            let from = CGPoint(x: cropRect.minX, y: cropRect.minY + cropRect.height / (CGFloat(gridLines) + 1) * CGFloat(i))
            
            path.move(to: from)
            path.addLine(to: CGPoint(x: cropRect.maxX, y: from.y))
        }
    
        path.stroke()
    }
}

// MARK: - AKImageCropperOverlayDelegate
//         _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _

extension AKImageCropperView: AKImageCropperTouchViewDelegate {
    
    func cropRectChanged(_ rect: CGRect) {
        
        self.setCropRect(rect)
    }
}
