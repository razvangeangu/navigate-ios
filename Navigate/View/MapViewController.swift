//
//  MapViewController
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SpriteKit
import CoreLocation

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var containerView: UIView!
    
    // The scene that holds the map nodes
    static var scene: SKScene!
    
    // Vars for gesture recognisers
    var lastScale: CGFloat = 0.0
    var previousLocation = CGPoint.zero
    var initialRotation: CGFloat = 0.0
    
    // Limits for the map
    let minWidth: CGFloat = 300
    let minHeight: CGFloat = 533
    let maxWidth: CGFloat = 1400
    let maxHeight: CGFloat = 4000
    
    static var map: SKTileMapNode!
    
    let bottomSheetVC = ScrollableBottomSheetViewController()
    var mapButtonsView: MapButtonsView!
    
    static var locationNode: SKSpriteNode!
    static var backgroundNode: SKSpriteNode!
    
    static var shouldCenterMap = false
    static var shouldRotateMap = false
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let oldFrame = view.frame
        view = SKView(frame: oldFrame)
        view.backgroundColor = .white
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "MapTilemapScene") {
                MapViewController.scene = scene
                
                // Initialise the static map
                MapViewController.map = scene.childNode(withName: "tileMap") as? SKTileMapNode
                MapViewController.map.zPosition = 0
                
                // Move backgroundNode (image map) under the tile map
                MapViewController.backgroundNode = scene.childNode(withName: "backgroundNode") as? SKSpriteNode
                MapViewController.backgroundNode?.zPosition = -1
                
                initLocationNode()
                
                // Set the scale mode to scale to fit the window
                MapViewController.scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(MapViewController.scene)
                view.ignoresSiblingOrder = true
                
                // Add the camera node
                let cameraNode = SKCameraNode()
                MapViewController.scene.addChild(cameraNode)
                MapViewController.scene.camera = cameraNode
                
                // Add the gesture to the view
                self.addGesturesRecognisers()
            }
        }
        
        mapButtonsView = MapButtonsView(frame: CGRect(x: view.bounds.maxX - 60, y: view.bounds.minY + 60, width: 40, height: 131))
        mapButtonsView.backgroundColor = .clear
        mapButtonsView.parentVC = self
        self.view.addSubview(mapButtonsView)
        
        initModel()
        
        addBottomSheetView()
        
        // Activate the tiles that have access points stored in core data
        MapViewController.resetTiles()
        
        locationManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    fileprivate func initLocationNode() {
        MapViewController.locationNode = MapViewController.scene.childNode(withName: "locationNode") as? SKSpriteNode
    }
    
    /**
     Initialise the model.
     */
    fileprivate func initModel() {
        // Connect to device that scans for Wi-Fi APs
        RGSharedDataManager.connect(to: "0x12AB")
        
        RGSharedDataManager.numberOfRows = MapViewController.map.numberOfRows
        RGSharedDataManager.numberOfColumns = MapViewController.map.numberOfRows
        
        RGSharedDataManager.floorLevel = 6
        RGSharedDataManager.setFloor(level: 6)
        RGSharedDataManager.mapImage = UIImagePNGRepresentation(UIImage(named: "bh_6th")!) as NSData?
        
        RGSharedDataManager.initData()
        
        // Set the app mode to dev to display log
        RGSharedDataManager.appMode = .dev
    }
    
    fileprivate func addGesturesRecognisers() {
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(MapViewController.handlePinch))
        view.addGestureRecognizer(pinchGesture)
        pinchGesture.delegate = self
        
        // Add pan gesture for movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.handlePan))
        view.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        
        // Add tap gesture for dev/client
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.handleTapFrom))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
        
//        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(MapViewController.handleRotation))
//        view.addGestureRecognizer(rotationGesture)
//        rotationGesture.delegate = self
    }
    
    /**
     Set tile blue as "active"
     
     - parameter column: The column of the tile.
     - parameter row: The row of the tile.
     - parameter type: The group type of the tile (as expressed by the RGTileType class)
     */
    static func setTileColor(column: Int, row: Int, type: RGTileType) {
        var tileGroup: SKTileGroup!
        
        switch type {
        case .sample:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "sample"})
            }
        case .saved:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "saved"})
            }
        case .location:
            do {
                tileGroup = MapViewController.map.tileSet.tileGroups.first(
                    where: {$0.name == "location"})
            }
        case .none:
            do {
                tileGroup = SKTileGroup.empty()
            }
        }
        
        MapViewController.map.setTileGroup(tileGroup, forColumn: column, row: row)
    }
    
    fileprivate static func displayDevTiles(column: Int, row: Int) {
        if RGSharedDataManager.tileHasData(column: column, row: row) {
            MapViewController.setTileColor(column: column, row: row, type: .saved)
        } else {
            MapViewController.setTileColor(column: column, row: row, type: .sample)
        }
    }
    
    /**
     Display blue tile if it contains data.
     */
    static func resetTiles() {
        for row in 0...MapViewController.map.numberOfRows {
            for column in 0...MapViewController.map.numberOfColumns {
                if RGSharedDataManager.appMode == .dev {
                    displayDevTiles(column: column, row: row)
                } else if RGSharedDataManager.appMode == .prod {
                    
                }
            }
        }
    }
    
    static func showCurrentLocation(_ currentLocation: (Int, Int)) {
        // If the locationNode is hidden, change alpha to 1 to display it
        if locationNode.alpha < 1 {
            locationNode.alpha = 1
        }
        
        // Get the location of the center of the tile that represents the current location
        let location = MapViewController.map.centerOfTile(atColumn: currentLocation.1, row: currentLocation.0)
        
        // Animate moving from the last location to the new position in the number of seconds
        let move = SKAction.move(to: location, duration: 0.3)
        
        // Add ease out effect
        move.timingMode = .easeInEaseOut
        
        // Run the animation
        locationNode.run(move, withKey: "moving")
        
        if shouldCenterMap {
            centerToLocation()
        }
    }
    
    /**
     Disconnect the bluetooth device and stop it on shaking device.
     */
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            RGSharedDataManager.disconnect()
        }
    }
    
    static func devLog(data: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        
        if RGSharedDataManager.appMode == .dev {
            debugPrint("\(formatter.string(from: date)) \(data)")
            prodLog("\(formatter.string(from: date)) \(data)")
        }
    }
    
    static func prodLog(_ data: String) {
        ScrollableBottomSheetViewController.status = data
    }
    
    fileprivate func addBottomSheetView() {
        self.addChildViewController(bottomSheetVC)
        self.view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParentViewController: self)
        bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: view.frame.width, height: view.frame.height)
        bottomSheetVC.updatePickerData()
        bottomSheetVC.updateTableData()
    }
    
    static func centerToLocation() {
        let tileLocation = RGLocalisation.currentLocation
        
        if tileLocation == (-1, -1) { return }
        
        let newPosition = map.centerOfTile(atColumn: tileLocation.1, row: tileLocation.0)
        
        // Animate moving from the last location to the new position in the number of seconds
        let move = SKAction.move(to: newPosition, duration: 0.3)
        
        // Add ease out effect
        move.timingMode = .easeOut
        
        // Run the animation
        MapViewController.scene.camera?.run(move, withKey: "localising")
    }
    
    static func resetCameraRotation() {
        MapViewController.shouldRotateMap = false
        let rotation = SKAction.rotate(toAngle: 0, duration: 0.3, shortestUnitArc: true)
        rotation.timingMode = .linear
        MapViewController.scene.camera?.run(rotation, withKey: "moving")
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? AdminViewController {
            destinationVC.modalPresentationStyle = .overFullScreen
            destinationVC.parentVC = self
        }
    }
}

