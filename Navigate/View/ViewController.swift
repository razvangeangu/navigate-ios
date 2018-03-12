//
//  ViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit
import CoreData

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let ble = BLEService()
    var scene: SKScene!
    
    var devLabel: UILabel!
    
    var floorLevel = 6
    var floor: Floor!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ble.connect(to: "0x12AB")
        
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
                
                // Add the gesture to the view
                addGestures()
            }
        }
        
        addDevLabel()
        self.floor = getFloor(level: self.floorLevel)
    }
    
    fileprivate func addGestures() {
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch))
        view.addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
        
        // Add pan gesture for movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan))
        view.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        // Add tap gesture for dev/client
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTapFrom))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
    }
    
    func addDevLabel() {
        devLabel = UILabel(frame: CGRect(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100))
        devLabel.backgroundColor = .black
        devLabel.text = "dev log"
        devLabel.numberOfLines = 4
        devLabel.textColor = .white
        devLabel.textAlignment = .center
        view.addSubview(devLabel)
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
//            ble.stopPi()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // Vars for gesture recognisers
    var lastScale: CGFloat = 0.0
    var previousLocation = CGPoint.zero
    
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
        
        saveDataToTile(column: column, row: row)
    }
    
    func saveDataToTile(column: Int, row: Int) {
        var saved = false
        
        for tileAny in floor.tiles! {
            if let tile = tileAny as? Tile {
                if tile.x == row && tile.y == column {
                    print("match")
                    
                    // TODO: save...
                    
                    saved = true
                    break
                }
                print(tile.floor as Any)
            }
        }
        
        if !saved {
            let tile = Tile(context: PersistenceService.context)
            tile.x = Int16(row)
            tile.y = Int16(column)
            tile.accessPoints = getAccessPoints()
            floor.addToTiles(tile)
        }
    }
    
    func getAccessPoints() -> NSSet? {
        let json = ble.getWiFiList()
        
        // TODO: parse json
        
        return nil
    }
    
    func setBlueTile(column: Int, row: Int, color: RGColor) {
        guard let map = scene.childNode(withName: "tileMap") as? SKTileMapNode else { return }
        var tileGroup: SKTileGroup!
        
        switch color {
        case .cyan:
            do {
                tileGroup = map.tileSet.tileGroups.first(
                    where: {$0.name == "cyan_box"})
            }
        case .purple:
            do {
                tileGroup = map.tileSet.tileGroups.first(
                    where: {$0.name == "purple_box"})
            }
        }
        map.setTileGroup(tileGroup, forColumn: column, row: row)
    }
    
    func getFloor(level: Int) -> Floor? {
        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        do {
            let floors = try PersistenceService.context.fetch(fetchRequest)
            for floor in floors {
                if floor.level == floorLevel {
                    return floor
                }
            }
        } catch {
            print("Error in Floor fetchRequest")
        }
        
        return nil
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
//    }
}


