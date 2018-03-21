//
//  MapButtonsView.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 16/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class MapButtonsView: UIView {
    
    // The parent view controller
    var parentVC: UIViewController!
    
    // Camera button
    var cameraButton: UIButton!
    
    // Location button
    var locationButton: UIButton!
    
    // The buttons view
    var buttonsView: UIView!
    
    // The heading view
    var headingView: UIView!
    
    // Number of touches for the location button
    var locationNumberOfTouches = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Add shadow to the view
        backgroundColor = UIColor.clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5.0
        
        // Add components
        addButtonsView()
        addCameraButton()
        addSeparator()
        addLocateButton()
        addHeadingButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Adds the buttons view and set style blured.
    */
    fileprivate func addButtonsView() {
        
        // Initiliase the buttons view
        buttonsView = UIView(frame: CGRect(x: self.bounds.minX, y: self.bounds.minY, width: self.bounds.width, height: self.bounds.height - 50))
        
        // Round the corners
        buttonsView.layer.cornerRadius = 10
        buttonsView.layer.masksToBounds = true
        
        // Add the blur effect style
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = buttonsView.bounds
        blur.isUserInteractionEnabled = false
        buttonsView.insertSubview(blur, at: 0)
        
        // Add it to the view
        self.addSubview(buttonsView)
    }
    
    /**
     Adds the camera button to the buttons view.
    */
    fileprivate func addCameraButton() {
        
        // Initialise the button
        cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        cameraButton.setTitleColor(.black, for: .normal)
        cameraButton.setBackgroundImage(UIImage(named: "ar"), for: .normal)
        cameraButton.addTarget(self, action: #selector(MapButtonsView.cameraTaped), for: .touchUpInside)
        
        // Add button to the buttons view
        buttonsView.addSubview(cameraButton)
    }
    
    /**
     Adds a separator between after the camera button.
    */
    fileprivate func addSeparator() {
        
        // Initialise the separator view
        let separator = UIView(frame: CGRect(x: 0, y: cameraButton.frame.height, width: 40, height: 1))
        separator.backgroundColor = .init(red: 216, green: 216, blue: 216, a: 1.0)
        
        // Add the separator to the buttons view
        buttonsView.addSubview(separator)
    }
    
    /**
     Adds the location button to the buttons view
    */
    fileprivate func addLocateButton() {
        
        // Initialise the button
        locationButton = UIButton(frame: CGRect(x: 0, y: cameraButton.frame.height + 1, width: 40, height: 40))
        locationButton.setTitleColor(.black, for: .normal)
        locationButton.setBackgroundImage(UIImage(named: "navigation_disabled"), for: .normal)
        locationButton.addTarget(self, action: #selector(MapButtonsView.locationTaped), for: .touchUpInside)
        
        // Add the button to the buttons view
        buttonsView.addSubview(locationButton)
    }
    
    /**
     Adds the heading button to the buttons view
    */
    fileprivate func addHeadingButton() {
        
        // Initialise the heading view
        headingView = UIView(frame: CGRect(x: 0, y: buttonsView.frame.height + 10, width: self.frame.width, height: self.frame.width))
        headingView.backgroundColor = .black
        headingView.layer.cornerRadius = self.frame.width / 2
        
        // Add the compass button in the center of the view
        let compassButton = UIButton(frame: CGRect(x: 0, y: 0, width: headingView.frame.width, height: headingView.frame.height))
        compassButton.addTarget(self, action: #selector(MapButtonsView.headingTaped), for: .touchUpInside)
        compassButton.setBackgroundImage(UIImage(named: "compass"), for: .normal)
        
        // Set the heading view hidden
        headingView.isHidden = true
        headingView.alpha = 0
        
        // Add the compass button to the heading view
        headingView.addSubview(compassButton)
        
        // Add the heading view to the view
        addSubview(headingView)
    }
}

extension MapButtonsView {
    /**
     Executes when the camera button is taped.
    */
    @objc func cameraTaped(_ sender: UIButton!) {
        (parentVC as? MapViewController)?.performSegue(withIdentifier: "arvc", sender: parentVC)
    }
    
    /**
     Executes when the location button is taped.
    */
    @objc func locationTaped() {
        
        // Center camera node to location
        MapViewController.centerToLocation()
        
        // Keep track of the number of touches
        locationNumberOfTouches += 1
        
        switch locationNumberOfTouches {
            
        // Reset case
        case 0:
            do {
                // Feedback
                UIView.transition(with: locationButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_disabled"), for: .normal)
                })
                
                // Disable control events
                MapViewController.shouldCenterMap = false
                MapViewController.shouldRotateMap = false
            }
            
        // Enable center map event
        case 1:
            do {
                // Feedback
                UIView.transition(with: locationButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_enabled"), for: .normal)
                })
                
                // Enable control event
                MapViewController.shouldCenterMap = true
            }
        
        // Enable rotate map event
        case 2:
            do {
                // Feedback
                UIView.transition(with: locationButton as UIButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_enabled_bearing"), for: .normal)
                })
                
                // Enable control event
                MapViewController.shouldRotateMap = true
                
                // Display the heading view
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.headingView.alpha = 1
                }) { _ in
                    self.headingView.isHidden = false
                }
            }
        
        // Disable events and reset camera node
        case 3:
            do {
                
                // Reset the number of touches
                locationNumberOfTouches = 0
                
                // Feedback
                UIView.transition(with: locationButton, duration: 0.2, options: .allowUserInteraction, animations: {
                    self.locationButton.setBackgroundImage(UIImage(named: "navigation_disabled"), for: .normal)
                })
                
                // Reset camera rotation
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
                    self.headingView.alpha = 0
                    MapViewController.resetCameraRotation()
                }) { _ in
                    self.headingView.isHidden = true
                }
                
                // Disable control event
                MapViewController.shouldCenterMap = false
            }
        default:
            break
        }
    }
    
    /**
     Executes when the heading button is taped.
     */
    @objc func headingTaped(_ sender: UIButton!) {
        
        // If executes any location control events
        if locationNumberOfTouches != 0 {
            
            // Feedback
            UIView.transition(with: locationButton, duration: 0.2, options: .allowUserInteraction, animations: {
                self.locationButton.setBackgroundImage(UIImage(named: "navigation_enabled"), for: .normal)
            })
        }
        
        // Reset camera rotation
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            self.headingView.alpha = 0
            MapViewController.resetCameraRotation()
        }) { _ in
            self.headingView.isHidden = true
        }
    }
}
