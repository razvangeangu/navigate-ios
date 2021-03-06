//
//  MapButtonsViewExtensions.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 21/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

extension MapButtonsView {
    /**
     Executes when the camera button is taped.
     */
    @objc func cameraTaped(_ sender: UIButton!) {
        if let parentVC = parentVC as? MapViewController {
            if !MapViewController.shouldShowPath {
                parentVC.presentAlert(title: "Error", message: "To enable Augmented Reality experiences, please set a destination first.", completion: nil)
            } else {
                parentVC.performSegue(withIdentifier: "arvc", sender: parentVC)
            }
        }
            
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
                    self.headingView.isHidden = false
                    self.headingView.alpha = 1
                })
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
