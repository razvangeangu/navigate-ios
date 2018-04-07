//
//  MapViewControllerExtensions.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit
import CoreLocation

extension MapViewController {
    
    /**
     Enable simultaneous recongition of multiple gestures.
    */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if gestureRecognizer.view != otherGestureRecognizer.view {
            return false
        } else {
            return true
        }
    }
    
    /**
     Handle tap for the development mode to save data for a certain tile
     and display feedback by setting it to the color type.
     
     - parameter tap: The tap gesture that has been recognised.
     */
    @objc func handleTapFrom(tap: UITapGestureRecognizer) {
        if RGSharedDataManager.appMode == .dev {
            if tap.state != .ended { return }
        
            // Get the row and column of the taped square/tile
            let tapLocation = tap.location(in: view)
        
            // Only activate gesture if bottomSheetVC is closed
            if tapLocation.y > MapViewController.bottomSheetVC.view.frame.minY {
                return
            }
        
            // Detect the location from the view in the scene
            let location = MapViewController.scene.convertPoint(fromView: tapLocation)
            
            // Check if location is in limits
            if location.x > MapViewController.backgroundNode.frame.maxX || location.x < MapViewController.backgroundNode.frame.minX || location.y > MapViewController.backgroundNode.frame.maxY || location.y < MapViewController.backgroundNode.frame.minY {
                MapViewController.prodLog("Taped location not on the map.")
                MapViewController.bottomSheetVC.removeLoadingAnimation()
                RGNavigation.previousDestinationTile = RGNavigation.destinationTile
                return
            }
        
            // Row and Column for the tapped location
            let column = MapViewController.map.tileColumnIndex(fromPosition: location)
            let row = MapViewController.map.tileRowIndex(fromPosition: location)
        
            // The tile definition for more access
            let _ = MapViewController.map.tileDefinition(atColumn: column, row: row)
        
            // Dev data
            MapViewController.devLog(data: "Touched Tile(\(column),\(row))")
                
            // If the model has been able to save data for the specific column and row
            if RGSharedDataManager.saveDataToTile(column: column, row: row) {
                
                // Save the tile (visually)
                MapViewController.setTileColor(column: column, row: row, type: RGSharedDataManager.tileType!)
            }
        } else if RGSharedDataManager.appMode == .prod {
            MapViewController.bottomSheetVC.addLoadingAnimation()
            
            if tap.state != .ended { return }
            
            // If external device is not connected then do not try to execute tap functions
            if !BLEService.isConnected { return }
            
            // Get the row and column of the taped square/tile
            let tapLocation = tap.location(in: view)
            
            // Only activate gesture if bottomSheetVC is closed
            if tapLocation.y > MapViewController.bottomSheetVC.view.frame.minY {
                return
            }
            
            if RGLocalisation.currentLocation == (-1, -1) { return }
            
            // Detect the location from the view in the scene
            let location = MapViewController.scene.convertPoint(fromView: tapLocation)
            
            // Check if location is in limits
            if location.x > MapViewController.backgroundNode.frame.maxX || location.x < MapViewController.backgroundNode.frame.minX || location.y > MapViewController.backgroundNode.frame.maxY || location.y < MapViewController.backgroundNode.frame.minY {
                MapViewController.prodLog("Could not find path to location.")
                MapViewController.bottomSheetVC.removeLoadingAnimation()
                RGNavigation.previousDestinationTile = RGNavigation.destinationTile
                return
            }
            
            // Row and Column for the tapped location
            let column = MapViewController.map.tileColumnIndex(fromPosition: location)
            let row = MapViewController.map.tileRowIndex(fromPosition: location)
            
            guard let destinationTile = RGSharedDataManager.getTile(col: column, row: row) else { return }
            RGNavigation.destinationTile = destinationTile
        }
    }
    
    /**
     Handle pan to move tha map around
     
     - parameter pan: The pan gesture that has been recognised.
     */
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        if MapViewController.mapButtonsView.locationNumberOfTouches > 0 {
            MapViewController.mapButtonsView.locationNumberOfTouches = -1
            MapViewController.mapButtonsView.locationTaped()
        }
        
        // Only activate gesture if bottomSheetVC is closed
        let panLocation = pan.location(in: self.view)
        if panLocation.y > MapViewController.bottomSheetVC.view.frame.minY {
            return
        }
        
        switch pan.state {
        case .began:
            do {
                // Save the previous location
                previousLocation = (MapViewController.scene.camera?.position)!
            }
        case .changed:
            do {
                // Set off set depending on the scale
                var offSet: CGFloat = 1.0
                offSet = 750 / MapViewController.scene.size.width
                if offSet != 1.0 {
                    offSet = offSet < 1 ? offSet + 1 : offSet - 1
                }
                
                // get the translation point
                let transPoint = pan.translation(in: self.view)
                
                pan.view?.transform = CGAffineTransform(rotationAngle: (MapViewController.scene.camera?.zRotation)!)
                MapViewController.scene.camera?.zRotation = 0
                
                let x = (transPoint.x * -offSet)
                let y = (transPoint.y * offSet)
                
                // calculate the new position
                let newPosition = previousLocation + CGPoint(x: x, y: y)
                
                // set the camera to the new position
                MapViewController.scene.camera?.position = newPosition
            }
        case .ended:
            do {
                // Get velocity of the pan
                let velocity = pan.velocity(in: self.view)
                
                // If the velocity is significant
                if velocity.y > 100 || velocity.y < -100 || velocity.x > 100 || velocity.x < -100 {
                    
                    // Get the current position
                    var newPosition = (MapViewController.scene.camera?.position)!
                    
                    // Add the distance that can be travelled in the number of seconds with the speed of velocity on the x axis
                    if (MapViewController.scene.camera?.position.x)! < previousLocation.x {
                        newPosition.x -= (previousLocation.x - (MapViewController.scene.camera?.position.x)! - velocity.x * 0.1)
                    }
                
                    // Add the distance that can be travelled in the number of seconds with the speed of velocity on the x axis
                    if (MapViewController.scene.camera?.position.x)! > previousLocation.x {
                        newPosition.x += ((MapViewController.scene.camera?.position.x)! - previousLocation.x + velocity.x * 0.1)
                    }
                
                    // Add the distance that can be travelled in the number of seconds with the speed of velocity on the y axis
                    if (MapViewController.scene.camera?.position.y)! > previousLocation.y {
                        newPosition.y += ((MapViewController.scene.camera?.position.y)! - previousLocation.y + velocity.y * 0.1)
                    }
                
                    // Add the distance that can be travelled in the number of seconds with the speed of velocity on the y axis
                    if (MapViewController.scene.camera?.position.y)! < previousLocation.y {
                        newPosition.y -= (previousLocation.y - (MapViewController.scene.camera?.position.y)! - velocity.y * 0.1)
                    }
                
                    // Animate moving from the last location to the new position in the number of seconds
                    let move = SKAction.move(to: newPosition, duration: 0.4)
                    
                    // Add ease out effect
                    move.timingMode = .easeOut
                    
                    // Run the animation
                    MapViewController.scene.camera?.run(move, withKey: "moving")
                }
            }
        default:
            break
        }
    }
    
    /**
     Handle pinch gesture to zoom in/zoom out to display the map accordingly.
     
     - parameter pinch: The pinch gesture that has been recognised.
     */
    @objc func handlePinch(pinch: UIPinchGestureRecognizer) {
        
        // Only activate gesture if bottomSheetVC is closed
        let pinchLocation = pinch.location(in: self.view)
        if pinchLocation.y > MapViewController.bottomSheetVC.view.frame.minY {
            return
        }
        
        switch pinch.state {
        case .began:
            do {
                // save the last scale
                self.lastScale = pinch.scale
            }
        case .changed:
            do {
                // get the scale from the last scale subtracting the current pinched scale
                let scale = 1 - (self.lastScale - pinch.scale)
                
                // get the new width and height matching the min and max sizes allowed
                let newWidth = max(minWidth, min(maxWidth, MapViewController.scene.size.width / scale))
                let newHeight = max(minHeight, min(maxHeight, MapViewController.scene.size.height / scale))
                
                // set the new size
                MapViewController.scene.size = CGSize(width: newWidth, height: newHeight)
                
                // save the last scale
                self.lastScale = pinch.scale
            }
        default:
            break
        }
    }
    
    /**
     A function to handle the rotation of the view using two fingers gesture.
     
     - parameter rotate: The gesture recogniser that triggers the event.
     */
    @objc func handleRotation(rotate: UIRotationGestureRecognizer) {
        switch rotate.state {
        case .began:
            do {
                initialRotation = atan2(rotate.view!.transform.b, rotate.view!.transform.a)
            }
        case .changed:
            do {
                let newRotation = initialRotation + rotate.rotation
                MapViewController.scene.camera?.zRotation = newRotation
            }
        default:
            break
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        MapViewController.shouldCenterMap = false
        
        return true
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Get the angle of Bush House relative to magnetic north
        let angle = CGFloat((newHeading.magneticHeading - 7).toRadians)
        
        // Get the heading for North
        let northAngle = CGFloat(newHeading.magneticHeading.toRadians)
        
        RGLocalisation.heading = Float(-angle)
        
        // Animate the location node
        let rotation = SKAction.rotate(toAngle: -angle, duration: 0.6, shortestUnitArc: true)
        rotation.timingMode = .linear
        MapViewController.locationNode.run(rotation, withKey: "rotatingLocationNodeBearing")
        
        if MapViewController.shouldRotateMap {
            
            // Animate the heading node
            UIView.animate(withDuration: 0.6, delay: 0, options: [.allowUserInteraction], animations: {
                MapViewController.mapButtonsView.headingView.transform = CGAffineTransform(rotationAngle: northAngle)
                
                // Animate the camera node
                let rotation = SKAction.rotate(toAngle: -angle, duration: 0.8, shortestUnitArc: true)
                rotation.timingMode = .easeOut
                MapViewController.scene.camera?.run(rotation, withKey: "rotatingCameraBearing")
            }, completion: nil)
        }
    }
}
