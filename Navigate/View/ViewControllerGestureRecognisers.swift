//
//  ViewControllerGestureRecognisers.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 12/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit

extension ViewController {
    
    /**
     Enable simultaneous recongition of multiple gestures.
    */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /**
     Handle tap for the development mode to save data for a certain tile
     and display feedback by setting it to the color cyan.
     
     - parameter tap: The tap gesture that has been recognised.
     */
    @objc func handleTapFrom(tap: UITapGestureRecognizer) {
        if tap.state != .ended { return }
        
        // Get the row and column of the taped square/tile
        let tapLocation = tap.location(in: view)
        
        // Detect the location from the view in the scene
        let location = scene.convertPoint(fromView: tapLocation)
        
        // get the parent child that holds the entire map
        guard let map = scene.childNode(withName: "tileMap") as? SKTileMapNode else { return }
        
        // Row and Column for the tapped location
        let column = map.tileColumnIndex(fromPosition: location)
        let row = map.tileRowIndex(fromPosition: location)
        
        // The tile definition for more access
        let _ = map.tileDefinition(atColumn: column, row: row)
        
        // Dev data
        ViewController.devLog(data: "Touched Tile(\(column),\(row))")
        
        // If the model has been able to save data for the specific column and row
        if model.saveDataToTile(column: column, row: row) {
            
            // Set the tile to cyan color
            setBlueTile(column: column, row: row, color: .cyan)
        }
    }
    
    /**
     Handle pan to move tha map around
     
     - parameter pan: The pan gesture that has been recognised.
     */
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            do {
                // Save the previous location
                previousLocation = (self.scene.camera?.position)!
            }
        case .changed:
            do {
                // get the translation point
                let transPoint = pan.translation(in: self.view)
                
                // calculate the new position
                let newPosition = previousLocation + CGPoint(x: transPoint.x * -1.0, y: transPoint.y * 1.0)
                
                // set the camera to the new position
                self.scene.camera?.position = newPosition
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
                let newWidth = max(533, min(1400, self.scene.size.width / scale))
                let newHeight = max(300, min(4000, self.scene.size.height / scale))
                
                // set the new size
                self.scene.size = CGSize(width: newWidth, height: newHeight)
                
                // save the last scale
                self.lastScale = pinch.scale
            }
        default:
            break
        }
    }
}
