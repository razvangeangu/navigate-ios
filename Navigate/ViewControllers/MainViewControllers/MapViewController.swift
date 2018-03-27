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
import ARKit

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    // A container view for visual effects
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
    
    // Map node
    static var map: SKTileMapNode!
    
    // The bottom view controller
    static var bottomSheetVC: ScrollableBottomSheetViewController!
    
    // Map control buttons
    static var mapButtonsView: MapButtonsView!
    
    // Map information view
    static var mapTimeAndDistanceView: MapTimeAndDistanceView!
    
    // The current location node
    static var locationNode: SKSpriteNode!
    
    // The background node
    static var backgroundNode: SKSpriteNode!
    
    // Booleans for the visuals controlled by the map buttons
    static var shouldCenterMap = false
    static var shouldRotateMap = false
    static var shouldShowPath = false {
        didSet {
            if shouldShowPath {
                MapViewController.mapTimeAndDistanceView.isHidden = false
            } else {
                MapViewController.mapTimeAndDistanceView.isHidden = true
                
                // Stop showing the path
                RGNavigation.destinationTile = nil
            }
        }
    }
    
    // The location manager for the heading/bearing of the device
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    // The navigation model
    static var navigation: RGNavigation!
    
    static var mapTileEdit: MapTileEditViewController!
    
    static func isARSupported() -> Bool {
        guard #available(iOS 11.0, *) else {
            return false
        }
        return ARConfiguration.isSupported
    }
    
    fileprivate func initView() {
        let oldFrame = self.view.frame
        self.view = SKView(frame: oldFrame)
        self.view.backgroundColor = .white
        
        if let view = self.view as! SKView? {
            if let scene = SKScene(fileNamed: "MapTilemapScene") {
                MapViewController.scene = scene
                
                // Initialise the static map
                MapViewController.map = scene.childNode(withName: "tileMap") as? SKTileMapNode
                MapViewController.map.zPosition = 0
                
                // Move backgroundNode (image map) under the tile map
                MapViewController.backgroundNode = scene.childNode(withName: "backgroundNode") as? SKSpriteNode
                MapViewController.backgroundNode?.zPosition = -1
                
                // Init the location node
                MapViewController.locationNode = scene.childNode(withName: "locationNode") as? SKSpriteNode
                
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
        
        // Init the core model
        self.initModel()
        
        // Add the bottom view
        self.addBottomSheetView()
        
        // Activate the tiles that have access points stored in core data
        MapViewController.resetTiles()
        
        // Add the map control buttons
        self.addMapButtonsView()
        
        // Add the map tile edit control buttons
        self.addMapTileEditButton()
        
        // Add time and distance view
        self.addTimeAndDistanceView()
        
        // Set the delegate for location manager to self for the bearing data
        self.locationManager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RGSharedDataManager.getCustomZone { (completed) in
            RGSharedDataManager.createSubscription()
            
            if completed {
                DispatchQueue.main.async {
                    self.initView()
                }
            } else {
                RGSharedDataManager.createCustomZone {
                    DispatchQueue.main.async {
                        self.initView()
                    }
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if RGSharedDataManager.appMode == .dev {
                RGSharedDataManager.disconnect()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? AdminViewController {
            destinationVC.modalPresentationStyle = .overFullScreen
        }
        
        if let destinationVC = segue.destination as? ARViewController {
            if MapViewController.shouldShowPath {
                if let shortestPath = RGNavigation.shortestPath {
                    destinationVC.updatePath(to: shortestPath)
                }
            }
        }
    }
    
    /**
     Initialise the model.
     */
    fileprivate func initModel() {
        // Connect to device that scans for Wi-Fi APs
        RGSharedDataManager.connect(to: "0x12AB")
        
        // Set the number of rows and columns for the map logic
        RGSharedDataManager.numberOfRows = MapViewController.map.numberOfRows
        RGSharedDataManager.numberOfColumns = MapViewController.map.numberOfRows
        
        // Initiliase data model in CoreData
        let mapImage = UIImagePNGRepresentation(UIImage(named: "bh_6th")!) as NSData?
        RGSharedDataManager.initData(floorLevel: 6, mapImage: mapImage!)
        
        // Init the navigation model
        MapViewController.navigation = RGNavigation()
    }
    
    /**
     Add gesture recognisers to the scene.
     */
    fileprivate func addGesturesRecognisers() {
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(MapViewController.handlePinch))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        // Add pan gesture for movement
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(MapViewController.handlePan))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // Add tap gesture for dev/client
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MapViewController.handleTapFrom))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    /**
     Initialises the bottom view and adds it to the view.
     */
    fileprivate func addBottomSheetView() {
        MapViewController.bottomSheetVC = ScrollableBottomSheetViewController()
        self.addChildViewController(MapViewController.bottomSheetVC)
        self.view.addSubview(MapViewController.bottomSheetVC.view)
        MapViewController.bottomSheetVC.didMove(toParentViewController: self)
        MapViewController.bottomSheetVC.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: view.frame.width, height: view.frame.height)
        MapViewController.bottomSheetVC.updatePickerData()
        MapViewController.bottomSheetVC.updateTableData()
        
        if RGSharedDataManager.appMode == .dev {
            MapViewController.bottomSheetVC.addDevButton()
        }
    }
    
    /**
     Initialises the control buttons for the map and adds it to the view.
     */
    fileprivate func addMapButtonsView() {
        // Add the control buttons
        MapViewController.mapButtonsView = MapButtonsView(frame: CGRect(x: view.safeAreaLayoutGuide.layoutFrame.width - 40 - 20, y: view.safeAreaLayoutGuide.layoutFrame.minY, width: 40, height: 131))
        MapViewController.mapButtonsView.backgroundColor = .clear
        MapViewController.mapButtonsView.parentVC = self
        self.view.addSubview(MapViewController.mapButtonsView)
    }
    
    /**
     Initiliases the map tile edit button and adds it to the view.
     
     Makes it hidden if the app mode is *.prod*
     */
    fileprivate func addMapTileEditButton() {
        // Add MapTileEdit
        MapViewController.mapTileEdit = MapTileEditViewController(frame: CGRect(x: MapViewController.mapButtonsView.frame.minX, y: MapViewController.mapButtonsView.frame.maxY, width: 40, height: 40))
        view.insertSubview(MapViewController.mapTileEdit, at: 0)
        
        if RGSharedDataManager.appMode == .prod {
            MapViewController.mapTileEdit.isHidden = true
        }
    }
    
    /**
     
     */
    fileprivate func addTimeAndDistanceView() {
        MapViewController.mapTimeAndDistanceView = MapTimeAndDistanceView(frame: CGRect(x: view.safeAreaInsets.left + 20, y: view.safeAreaInsets.top, width: 120, height: 50))
        view.insertSubview(MapViewController.mapTimeAndDistanceView, at: 0)
        
        MapViewController.mapTimeAndDistanceView.isHidden = true
    }
    
    /**
     Set tile blue as "active"
     
     - parameter column: The column of the tile.
     - parameter row: The row of the tile.
     - parameter type: The group type of the tile (as expressed by the CDTileType class)
     */
    static func setTileColor(column: Int, row: Int, type: CDTileType) {
        var tileGroup: SKTileGroup!
        
        switch type {
        case .none:
            do {
                tileGroup = SKTileGroup.empty()
            }
        default:
            do {
                tileGroup = map.tileSet.tileGroups.first(where: {$0.name == type.rawValue})
            }
        }
        
        map.setTileGroup(tileGroup, forColumn: column, row: row)
    }
    
    /**
     Display tiles for the developer view.
     */
    fileprivate static func displayDevTiles(column: Int, row: Int) {
        guard let tile = RGSharedDataManager.getTile(col: column, row: row) else { return }
        
        if let type = tile.type {
            guard let tileType = CDTileType(rawValue: type) else { return }
            setTileColor(column: column, row: row, type: tileType)
        } else {
            setTileColor(column: column, row: row, type: .sample)
        }
    }
    
    /**
     Remove tiles for production view.
     */
    fileprivate static func removeDevTiles(column: Int, row: Int) {
        setTileColor(column: column, row: row, type: .none)
    }
    
    /**
     Reset all tiles to their color
     */
    fileprivate static func resetTiles() {
        for row in 0...map.numberOfRows {
            for column in 0...map.numberOfColumns {
                if RGSharedDataManager.appMode == .dev {
                    displayDevTiles(column: column, row: row)
                } else if RGSharedDataManager.appMode == .prod {
                    removeDevTiles(column: column, row: row)
                }
            }
        }
    }
    
    /**
     A method that shows a node on the map that represents the location of the device.
     
     - parameter currentLocation: A pair that represents the row and column of the position.
     */
    static func showCurrentLocation(_ currentLocation: (Int, Int)) {
        // If the locationNode is hidden, change alpha to 1 to display it
        if locationNode.alpha < 1 {
            locationNode.alpha = 1
            
            // Enable buttons
            mapButtonsView.enableButtons()
        }
        
        // Get the location of the center of the tile that represents the current location
        let location = map.centerOfTile(atColumn: currentLocation.1, row: currentLocation.0)
        
        // Animate moving from the last location to the new position in the number of seconds
        let move = SKAction.move(to: location, duration: 0.3)
        
        // Add ease out effect
        move.timingMode = .easeInEaseOut
        
        // Run the animation
        locationNode.run(move, withKey: "moving")
        
        // Center the map if option is activated
        if shouldCenterMap {
            centerToLocation()
        }
    }
    
    /**
     A method that displays development logs to the view and console.
     
     - parameter data: String containing data to be displayed.
     */
    static func devLog(data: String) {
        if RGSharedDataManager.appMode == .dev {
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSSS"
            
            debugPrint("\(formatter.string(from: date)) \(data)")
            prodLog("\(formatter.string(from: date)) \(data)")
        }
    }
    
    /**
     Displays as a status label the current log for production mode.
     
     - parameter data: String containing data to be displayed.
     */
    static func prodLog(_ data: String) {
        ScrollableBottomSheetViewController.status = data
    }
    
    /**
     Centers the camera view to the current location of the device.
     */
    static func centerToLocation() {
        let tileLocation = RGLocalisation.currentLocation
        
        // If no location was found stop
        if tileLocation == (-1, -1) { return }
        
        // Get the new position of the camera node for the current location
        let newPosition = map.centerOfTile(atColumn: tileLocation.1, row: tileLocation.0)
        
        // Animate moving from the last location to the new position in the number of seconds
        let move = SKAction.move(to: newPosition, duration: 0.3)
        
        // Add ease out effect
        move.timingMode = .easeOut
        
        // Run the animation
        scene.camera?.run(move, withKey: "localising")
    }
    
    /**
     Resets the camera rotation to initial angle (0) and stops the *shouldRotate* event.
     */
    static func resetCameraRotation() {
        shouldRotateMap = false
        
        let rotation = SKAction.rotate(toAngle: 0, duration: 0.3, shortestUnitArc: true)
        rotation.timingMode = .linear
        scene.camera?.run(rotation, withKey: "moving")
    }
    
    /**
     Resets the view accordingly to the app mode.
     
     - parameter for: App mode to be switched to.
     */
    static func resetView(for appMode: AppMode) {
        DispatchQueue.main.async {
            switch appMode {
            case .dev:
                do {
                    resetTiles()
                    bottomSheetVC.addDevButton()
                    if MapViewController.mapTileEdit != nil {
                        MapViewController.mapTileEdit.isHidden = false
                    }
                }
            case .prod:
                do{
                    resetTiles()
                    bottomSheetVC.removeDevButton()
                    
                    if MapViewController.mapTileEdit != nil {
                        MapViewController.mapTileEdit.isHidden = true
                    }
                }
            }
        }
    }
    
    /**
     Changes the texture of the background node (which represents the map)
     
     - parameter to: The image data.
     */
    static func changeMap(to imageData: NSData?) {
        if let imageData = imageData as Data? {
            if let image = UIImage(data: imageData) {
                backgroundNode.texture = SKTexture(cgImage: image.cgImage!)
            }
        }
    }
    
    /**
     Show the shortest path to the tile on the map
     
     - parameter to: The destination location as a **Tile**.
     */
    static func showPath(to tile: Tile) {
        if RGSharedDataManager.appMode != .dev {
            if let fromTile = RGSharedDataManager.getTile(col: RGLocalisation.currentLocation.1, row: RGLocalisation.currentLocation.0) {
                RGNavigation.moveTo(fromTile: fromTile, toTile: tile)
            }
            
            guard let currentPath = RGNavigation.shortestPath else { return }
            
            MapViewController.mapTimeAndDistanceView.distance = Float(currentPath.count - 1) * RGSharedDataManager.tileLength
            
            resetTiles()
            
            for tile in currentPath {
                setTileColor(column: Int(tile.col), row: Int(tile.row), type: .navigation)
            }
        }
    }
    
    /**
     Remove the location node from the view
     */
    static func removeLocationNode() {
        if locationNode.alpha == 1 {
            locationNode.alpha = 0
            MapViewController.devLog(data: "Location not found..")
        }
    }
    
    static func reloadData() {
        DispatchQueue.main.async {
            bottomSheetVC.updatePickerData()
            bottomSheetVC.updateTableData()
        }
    }
}

