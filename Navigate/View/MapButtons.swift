//
//  MapButtons.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 16/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class MapButtons: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        backgroundColor = UIColor.clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5.0
        
        addButtons()
    }
    
    fileprivate func addButtons() {
        let buttonsView = UIView(frame: self.bounds)
        buttonsView.layer.cornerRadius = 10
        buttonsView.layer.masksToBounds = true
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = buttonsView.bounds
        blur.isUserInteractionEnabled = false
        buttonsView.insertSubview(blur, at: 0)
        
        let cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        cameraButton.setTitleColor(.black, for: .normal)
        cameraButton.setImage(UIImage(named: "ar"), for: .normal)
        buttonsView.addSubview(cameraButton)
        
        let locationButton = UIButton(frame: CGRect(x: 0, y: cameraButton.frame.height + 2, width: 40, height: 40))
        locationButton.setTitleColor(.black, for: .normal)
        locationButton.setImage(UIImage(named: "location"), for: .normal)
        buttonsView.addSubview(locationButton)
        
        self.addSubview(buttonsView)
    }
}
