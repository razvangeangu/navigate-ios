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
    
    // The scene that holds the map nodes
    var scene: SKScene!
    
    // Developer label to display information
    fileprivate static var devLabel: UILabel!
    
    // Reference to the data model
    let model = RGData()
    
    // Vars for gesture recognisers
    var lastScale: CGFloat = 0.0
    var previousLocation = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initModel()
        
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
                self.addGesturesRecognisers()
            }
        }
        
        // Add the developer label to show different events
        addDevLabel()
        
        // Activate the tiles that have access points stored in core data
        activateTiles()
    }
    
    /**
     Initialise the model.
     */
    fileprivate func initModel() {
        // Connect to device that scans for Wi-Fi APs
        model.connect(to: "0x12AB")
        
        // Set the floor level
        model.setFloor(level: 6)
    }
    
    fileprivate func addGesturesRecognisers() {
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
    
    /**
     Construct and add development label to the view.
     */
    fileprivate func addDevLabel() {
        ViewController.devLabel = UILabel(frame: CGRect(x: 0, y: view.frame.height - 100, width: view.frame.width, height: 100))
        ViewController.devLabel.backgroundColor = .black
        ViewController.devLabel.text = "#"
        ViewController.devLabel.numberOfLines = 4
        ViewController.devLabel.textColor = .white
        ViewController.devLabel.textAlignment = .center
        view.addSubview(ViewController.devLabel)
    }
    
    /**
     Set tile blue as "active"
     
     - parameter column: The column of the tile.
     - parameter row: The row of the tile.
     - parameter color: The color that can be .cyan or .purple
     */
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
    
    /**
     Display blue tile if it contains data.
     */
    func activateTiles() {
        guard let map = scene.childNode(withName: "tileMap") as? SKTileMapNode else { return }
        for row in 0...map.numberOfRows {
            for column in 0...map.numberOfColumns {
                if model.accessPointHasData(column: column, row: row) {
                    print("YES! \(column), \(row)")
                    setBlueTile(column: column, row: row, color: .cyan)
                }
            }
        }
    }
    
    /**
     Disconnect the bluetooth device and stop it on shaking device.
     */
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            model.disconnect()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func devLog(data: String) {
        
    }
}


