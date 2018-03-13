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
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handleTapFrom(tap: UITapGestureRecognizer) {
        if tap.state != .ended { return }
        
        // Get the row and column of the taped square/tile
        let tapLocation = tap.location(in: view)
        let location = scene.convertPoint(fromView: tapLocation)
        guard let map = scene.childNode(withName: "tileMap") as? SKTileMapNode else { return }
        let column = map.tileColumnIndex(fromPosition: location)
        let row = map.tileRowIndex(fromPosition: location)
        let _ = map.tileDefinition(atColumn: column, row: row)
        
        // Dev data
        devLabel.text = "Touched Tile(\(column),\(row))"
        
        if model.saveDataToTile(column: column, row: row) {
            setBlueTile(column: column, row: row, color: .cyan)
        }
    }
    
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            do {
                previousLocation = (self.scene.camera?.position)!
            }
        case .changed:
            do {
                let transPoint = pan.translation(in: self.view)
                let newPosition = previousLocation + CGPoint(x: transPoint.x * -1.0, y: transPoint.y * 1.0)
                self.scene.camera?.position = newPosition
            }
        default:
            break
        }
    }
    
    @objc func handlePinch(pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began:
            do {
                self.lastScale = pinch.scale
            }
        case .changed:
            do {
                let scale = 1 - (self.lastScale - pinch.scale)
                
                let newWidth = max(533, min(1400, self.scene.size.width / scale))
                let newHeight = max(300, min(4000, self.scene.size.height / scale))
                
                self.scene.size = CGSize(width: newWidth, height: newHeight)
                self.lastScale = pinch.scale
            }
        default:
            break
        }
    }
}
