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
    
    var headingView: UIView!
    
    var parentVC: UIViewController!
    
    var locationNumberOfTouches = 0
    
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
        addHeadingButton()
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
        buttonsView = UIView(frame: CGRect(x: self.bounds.minX, y: self.bounds.minY, width: self.bounds.width, height: self.bounds.height - 50))
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
        cameraButton.setBackgroundImage(UIImage(named: "ar"), for: .normal)
        
        cameraButton.addTarget(self, action: #selector(MapButtonsView.cameraTaped), for: .touchUpInside)
        
        buttonsView.addSubview(cameraButton)
    }
    
    @objc fileprivate func cameraTaped(_ sender: UIButton!) {
        (parentVC as? MapViewController)?.performSegue(withIdentifier: "arvc", sender: parentVC)
    }
    
    fileprivate func addLocateButton() {
        locationButton = UIButton(frame: CGRect(x: 0, y: cameraButton.frame.height + 1, width: 40, height: 40))
        locationButton.setTitleColor(.black, for: .normal)
        locationButton.setBackgroundImage(UIImage(named: "navigation_disabled"), for: .normal)
        
        locationButton.addTarget(self, action: #selector(MapButtonsView.locationTaped), for: .touchUpInside)
        
        buttonsView.addSubview(locationButton)
    }
    
    @objc func locationTaped() {
        MapViewController.centerToLocation()
        locationNumberOfTouches += 1
        switch locationNumberOfTouches {
        case 0:
            do {
                UIView.transition(with: locationButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_disabled"), for: .normal)
                })
                MapViewController.shouldCenterMap = false
                MapViewController.shouldRotateMap = false
            }
        case 1:
            do {
                UIView.transition(with: locationButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_enabled"), for: .normal)
                })
                MapViewController.shouldCenterMap = true
            }
        case 2:
            do {
                UIView.transition(with: locationButton as UIButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_enabled_bearing"), for: .normal)
                })
                MapViewController.shouldRotateMap = true
                
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.headingView.alpha = 1
                }) { _ in
                    self.headingView.isHidden = false
                }
            }
        case 3:
            do {
                locationNumberOfTouches = 1
                
                UIView.transition(with: locationButton, duration: 0.2, options: .allowUserInteraction, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_disabled"), for: .normal)
                })
                
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.headingView.alpha = 0
                    MapViewController.resetCameraRotation()
                }) { _ in
                    self.headingView.isHidden = true
                }
                
                MapViewController.shouldCenterMap = false
            }
        default:
            break
        }
    }
    
    fileprivate func addHeadingButton() {
        headingView = UIView(frame: CGRect(x: 0, y: buttonsView.frame.height + 10, width: self.frame.width, height: self.frame.width))
        headingView.backgroundColor = .black
        headingView.layer.cornerRadius = self.frame.width / 2
        
        let compassButton = UIButton(frame: CGRect(x: 0, y: 0, width: headingView.frame.width, height: headingView.frame.height))
        compassButton.addTarget(self, action: #selector(MapButtonsView.headingTaped), for: .touchUpInside)
        compassButton.setBackgroundImage(UIImage(named: "compass"), for: .normal)
        headingView.isHidden = true
        headingView.alpha = 0
        
        headingView.addSubview(compassButton)
        
        addSubview(headingView)
    }
    
    @objc fileprivate func headingTaped(_ sender: UIButton!) {
        
        print("button pressed")
        
        if locationNumberOfTouches != 0 {
            UIView.transition(with: locationButton, duration: 0.2, options: .allowUserInteraction, animations: {
                self.locationButton.setBackgroundImage(UIImage(named: "navigation_enabled"), for: .normal)
            })
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.headingView.alpha = 0
            MapViewController.resetCameraRotation()
        }) { _ in
            self.headingView.isHidden = true
        }
    }
}
