//
//  MapViewControllerGestureRecognisers.swift
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
     and display feedback by setting it to the color cyan.
     
     - parameter tap: The tap gesture that has been recognised.
     */
    @objc func handleTapFrom(tap: UITapGestureRecognizer) {
        if RGSharedDataManager.appMode == .dev {
            if tap.state != .ended { return }
        
            // If external device is not connected then do not try to execute tap functions
            if !BLEService.isConnected { return }
        
            // Get the row and column of the taped square/tile
            let tapLocation = tap.location(in: view)
        
            // Only activate gesture if bottomSheetVC is closed
            if tapLocation.y > bottomSheetVC.view.frame.minY {
                return
            }
            
            // If there is no selected room
            if RGSharedDataManager.selectedRoom.isEmpty {
                
                // Give feedback to the admin
                MapViewController.devLog(data: "A room needs to be selected")
                return
            }
        
            // Detect the location from the view in the scene
            let location = MapViewController.scene.convertPoint(fromView: tapLocation)
        
            // Row and Column for the tapped location
            let column = MapViewController.map.tileColumnIndex(fromPosition: location)
            let row = MapViewController.map.tileRowIndex(fromPosition: location)
        
            // The tile definition for more access
            let _ = MapViewController.map.tileDefinition(atColumn: column, row: row)
        
            // Dev data
            MapViewController.devLog(data: "Touched Tile(\(column),\(row))")
        
            // If the model has not got any data for the specified location proceed
            if !RGSharedDataManager.accessPointHasData(column: column, row: row) {
                
                // If the model has been able to save data for the specific column and row
                if RGSharedDataManager.saveDataToTile(column: column, row: row) {
                    
                    // Save the tile (visually)
                    MapViewController.setTileColor(column: column, row: row, type: .saved)
                }
            } else {
                MapViewController.devLog(data: "AccessPoint already has data")
            }
        }
    }
    
    /**
     Handle pan to move tha map around
     
     - parameter pan: The pan gesture that has been recognised.
     */
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        if mapButtonsView.locationNumberOfTouches > 0 {
            mapButtonsView.locationNumberOfTouches = -1
            mapButtonsView.locationTaped()
        }
        
        // Only activate gesture if bottomSheetVC is closed
        let panLocation = pan.location(in: self.view)
        if panLocation.y > bottomSheetVC.view.frame.minY {
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
        if pinchLocation.y > bottomSheetVC.view.frame.minY {
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
        let angle = CGFloat((newHeading.trueHeading - 60).toRadians)
        let northAngle = CGFloat(newHeading.trueHeading.toRadians)
        
        UIView.animate(withDuration: 0.3, delay: 0.4, options: [.curveEaseOut, .allowUserInteraction], animations: {
            let rotation = SKAction.rotate(toAngle: -angle, duration: 0.3, shortestUnitArc: true)
            rotation.timingMode = .linear
            MapViewController.locationNode.run(rotation, withKey: "rotatingLocationNodeBearing")
        }, completion: nil)
        
        if MapViewController.shouldRotateMap {
            UIView.animate(withDuration: 0.3, delay: 0.4, options: [.curveEaseOut, .allowUserInteraction], animations: {
                self.mapButtonsView.headingView.transform = CGAffineTransform(rotationAngle: -northAngle)
                
                let rotation = SKAction.rotate(toAngle: -angle, duration: 0.3, shortestUnitArc: true)
                rotation.timingMode = .linear
                MapViewController.scene.camera?.run(rotation, withKey: "rotatingCameraBearing")
            }, completion: nil)
        }
    }
}
