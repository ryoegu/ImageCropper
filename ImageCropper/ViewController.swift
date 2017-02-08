//
//  ViewController.swift
//  ImageCropper
//
//  Created by Ryo Eguchi on 2017/02/01.
//  Copyright © 2017年 Ryo Eguchi. All rights reserved.
//

import UIKit

class ViewController: UIViewController,AKImageCropperViewDelegate {
    
    @IBOutlet weak var cropView: AKImageCropperView!
    
    @IBOutlet var label: UILabel!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cropView.image = UIImage(named: "shumpei.jpg")
        
        
        if cropView.overlayViewIsActive {
            
            cropView.dismissOverlayViewAnimated(true) { () -> Void in
                
                print("Frame disabled")
            }
        } else {
            
            cropView.showOverlayViewAnimated(true, withCropFrame: nil, completion: { () -> Void in
                
                print("Frame active")
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cropView.refresh()
    }


}

