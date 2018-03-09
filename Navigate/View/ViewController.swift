//
//  ViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let ble = BLEService()
    var scene: SKScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()

//        ble.connect(to: "0x12AB")
        
        let oldFrame = view.frame
        view = SKView(frame: oldFrame)
        view.backgroundColor = .white
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "MapTilemapScene") {
                self.scene = scene
                
                // Set the scale mode to scale to fit the window
                self.scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(self.scene)
                view.ignoresSiblingOrder = true
                
                // Add the camera node
                let cameraNode = SKCameraNode()
                self.scene.addChild(cameraNode)
                self.scene.camera = cameraNode
                
                // Add gestures
                let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch))
                view.addGestureRecognizer(pinchGesture)
                pinchGesture.delegate = self

                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan))
                view.addGestureRecognizer(panGesture)
                panGesture.delegate = self
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapFrom))
                tapGesture.numberOfTapsRequired = 1
                tapGesture.numberOfTouchesRequired = 1
                view.addGestureRecognizer(tapGesture)
                tapGesture.delegate = self
            }
        }
        
    }
    
    @objc func handleTapFrom(tap: UITapGestureRecognizer) {
        if tap.state != .ended { return }
        
        let tapLocation = tap.location(in: view)
        let location = scene.convertPoint(fromView: tapLocation)
        guard let map = scene.childNode(withName: "tileMap") as? SKTileMapNode else { return }
        let column = map.tileColumnIndex(fromPosition: location)
        let row = map.tileRowIndex(fromPosition: location)
        let tile = map.tileDefinition(atColumn: column, row: row)
        print(tile)
        
//        print("Row: \(row) • Column: \(column)")
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    var lastScale: CGFloat = 0.0
    var previousLocation = CGPoint.zero
    
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
                
                let newWidth = max(533, min(896, self.scene.size.width / scale))
                let newHeight = max(300, min(2500, self.scene.size.height / scale))
                
                self.scene.size = CGSize(width: newWidth, height: newHeight)
                self.lastScale = pinch.scale
            }
        default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        ble.write(command: Commands.updateServer.rawValue)
//        let command = "cd /usr/local/bin/server/ && git pull && forever restartall"
//        piPeripheral.writeValue(command.data(using: .utf8)!, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
//        print("Writing command: \(command)")
        
        // CoreData example
        //        let floor = Floor(context: PersistenceService.context)
        //        floor.level = 6
        //        PersistenceService.saveContext()
        
        //        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        //        do {
        //            let floors = try PersistenceService.context.fetch(fetchRequest)
        //            for floor in floors {
        //                print(floor.level)
        //            }
        //        } catch {
        //            print("Error in Floor fetchRequest")
        //        }
//    }
}


