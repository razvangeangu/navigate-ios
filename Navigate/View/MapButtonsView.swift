//
//  MapButtonsView.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 16/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class MapButtonsView: UIView {
    
    private var cameraButton: UIButton!
    private var locationButton: UIButton!
    private var buttonsView: UIView!
    
    var parentVC: UIViewController!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5.0
        
        addButtonsView()
        addCameraButton()
        addSeparator()
        addLocateButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func addSeparator() {
        let separator = UIView(frame: CGRect(x: 0, y: cameraButton.frame.height, width: 40, height: 1))
        separator.backgroundColor = .init(red: 216, green: 216, blue: 216, a: 1.0)
        buttonsView.addSubview(separator)
    }
    
    fileprivate func addButtonsView() {
        buttonsView = UIView(frame: self.bounds)
        buttonsView.layer.cornerRadius = 10
        buttonsView.layer.masksToBounds = true
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = buttonsView.bounds
        blur.isUserInteractionEnabled = false
        buttonsView.insertSubview(blur, at: 0)
        
        self.addSubview(buttonsView)
    }
    
    fileprivate func addCameraButton() {
        cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        cameraButton.setTitleColor(.black, for: .normal)
        cameraButton.setImage(UIImage(named: "ar"), for: .normal)
        
        cameraButton.addTarget(self, action: #selector(MapButtonsView.cameraTaped), for: .touchUpInside)
        
        buttonsView.addSubview(cameraButton)
    }
    
    @objc fileprivate func cameraTaped(sender: UIButton!) {
        (parentVC as? MapViewController)?.performSegue(withIdentifier: "arvc", sender: parentVC)
    }
    
    fileprivate func addLocateButton() {
        locationButton = UIButton(frame: CGRect(x: 0, y: cameraButton.frame.height + 1, width: 40, height: 40))
        locationButton.setTitleColor(.black, for: .normal)
        locationButton.setImage(UIImage(named: "navigation"), for: .normal)
        
        locationButton.addTarget(self, action: #selector(MapButtonsView.locationTaped), for: .touchUpInside)
        
        buttonsView.addSubview(locationButton)
    }
    
    @objc fileprivate func locationTaped(sender: UIButton!) {
        MapViewController.centerToLocation()
    }
}
