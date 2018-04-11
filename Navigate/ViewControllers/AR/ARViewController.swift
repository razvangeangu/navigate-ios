//
//  ViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 17/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var ringNode: ARRing!
    
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    
    var xs: [Float]!
    var zs: [Float]!
    var pos: Int = 0
    
    private var didFinishPath = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        sceneView.isUserInteractionEnabled = true
        
        // Init the ring node
        ringNode = ARRing()
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set ourselfs as a delegate for the session
        sceneView.session.delegate = self
        
        // Init the navigation elements
        initBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    /**
     A function that updates the path accordingly to the orientation of the device.
     
     - parameter to path: A sequence of **Tile** objects that represent the path to be navigated in AR.
     */
    func updatePath(to path: [Tile]) {
        
        // Init the xs and zs for the AR
        var xs = [Float]()
        var zs = [Float]()
        
        var previousStep = (0, 0)
        
        // For each step in reversed way (A* gives the path in reverse)
        for step in path.reversed() {
            let x = Int(step.col)
            let z = Int(step.row)
            
            // If this is the first iteration
            if xs.count == 0 && zs.count == 0 {
                xs.append(0)
                zs.append(0)
                
                // Set the previous step
                previousStep = (x, z)
                
                continue
            }
            
            // Set the next step
            let nextStep = getNextStep(from: previousStep, to: (x, z))
            
            // Append the x and z to the navigation lists
            xs.append(Float(nextStep.1))
            zs.append(Float(nextStep.0))
            
            // Set the previous step
            previousStep = (x, z)
        }
        
        // Set the navigation lists
        self.xs = xs
        self.zs = zs
    }
    
    /**
     A function that calculates the next step in AR based on the orientation of the device and the path steps.
     
     - parameter from currentLocation: The current location of our path.
     - parameter to step: The next step in the path from the current location.
     
     - Returns: An pair of **Int** that represent the z and x of the next step.
     */
    private func getNextStep(from currentLocation: (Int, Int), to step: (Int, Int)) -> (Int, Int) {
        var x: Int!
        var z: Int!
        
        let currentLocationRow = currentLocation.1
        let currentLocationColumn = currentLocation.0

        let stepRow = step.1
        let stepColumn = step.0
        
        let distance = Int(RGSharedDataManager.tileLength * 2)

        if stepRow == currentLocationRow - 1 {
            // back
            z = -distance
        } else if stepRow == currentLocationRow + 1 {
            // front
            z = distance
        } else {
            z = 0
        }

        if stepColumn == currentLocationColumn + 1 {
            // left
            x = -distance
        } else if stepColumn == currentLocationColumn - 1 {
            // right
            x = distance
        } else {
            x = 0
        }
        
        return (x, z)
    }
}

extension ARViewController {
    
    /**
     A function to init and add a back button to the AR view.
     */
    fileprivate func initBackButton() {
        let backButton = RGBackButton(frame: CGRect(x: view.frame.minX + 20, y: view.frame.minY + 40, width: 40, height: 40))
        backButton.addTarget(self, action: #selector(ARViewController.didPressBackButton), for: .touchUpInside)
        view.addSubview(backButton)
    }
    
    /**
     A function for the back button to dismiss the view when pressed.
     */
    @objc func didPressBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ARViewController {
    
    /**
     A function that moves the ring to a position relative to the camera node.
     */
    fileprivate func moveRing(to position: SCNVector3) {
        ringNode.position = position
        sceneView.scene.rootNode.addChildNode(ringNode)
    }
    
    /**
     A function that removes the ring from the scene view.
     */
    fileprivate func removeRing() {
        if ringNode.parent != nil {
            ringNode.removeFromParentNode()
        }
    }
}

extension ARViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Get the transform from the frame and the current ring node
        let cameraTransform = frame.camera.transform
        let nodeTransform = ringNode.transform
        
        // Get the position in x y z in the scene view of the device
        let cameraPosition = SCNVector3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        // Get the position in x y z in the scene view of the ring
        let nodePosition = SCNVector3(
            nodeTransform.m41,
            nodeTransform.m42,
            nodeTransform.m43
        )
        
        if pos == 0 {
            turn()
        }
        
        if pos < xs.count {
            if isInLimits(nodePosition: nodePosition, cameraPosition: cameraPosition, offset: 0.5) {

                // Give haptic feedback to the user
                generator.impactOccurred()

                moveRing(to: SCNVector3(x: cameraPosition.x + xs[pos], y: 0, z: cameraPosition.z + zs[pos]))
                
                // To move 2m because tile size is 1.5m
                pos += 2
                
                if pos >= xs.count {
                    didFinishPath = true
                }
            }
        } else {
            if didFinishPath {
                removeRing()
                self.presentAlert(title: "Success", message: "Arrived at the destination") {
                    self.dismiss(animated: true, completion: nil)
                }
                didFinishPath = false
            }
        }
    }
    
    /**
     A function that calculates the turn based on the orientation of the device
     */
    fileprivate func turn() {
        
        // If the device heading is available
        if let heading = RGPositioning.heading {
            
            let headingDegrees = abs(heading.toDegrees)
            let degrees: [RGCardinals] = [RGCardinals.north, RGCardinals.east, RGCardinals.south, RGCardinals.west]
            let degreesDifferences = degrees.map({ abs($0.rawValue - headingDegrees) })
            let angle = degrees[degreesDifferences.index(of: degreesDifferences.min()!)!]
            
            // If there is a shortest path found
            if let shortestPath = RGNavigation.shortestPath {
                let currentStep = shortestPath[shortestPath.count - 1]
                let nextStep = shortestPath[shortestPath.count - 2]
                
                // Get the positioning information
                let currentLocation = (Int(currentStep.col), Int(currentStep.row))
                let nextLocation = (Int(nextStep.col), Int(nextStep.row))
                let turn = getTurn(from: currentLocation, to: nextLocation)
                
                // Map the results based on the initial orientation of the device
                if xs != nil && zs != nil {
                    if angle == .east || angle == .west {
                        if turn == .north || turn == .south {
                            let oldXs = xs!
                            xs = zs.map({ -$0 })
                            zs = oldXs.map({ -$0 })
                        } else if (angle == .east && turn == .west) || (angle == .west && turn == .east) {
                            zs = zs.map({ -$0 })
                            xs = xs.map({ -$0 })
                        }
                    } else if angle == .south {
                        if turn == .west || turn == .east {
                            let oldXs = xs!
                            xs = zs.map({ -$0 })
                            zs = oldXs.map({ -$0 })
                        } else if turn == .north {
                            zs = zs.map({ -$0 })
                            xs = xs.map({ -$0 })
                        }
                    }
                }
            }
        }
    }
    
    /**
     A function to get a turn from the 2D location to the next step.
     
     - parameter from currentLocation: The current location of our path.
     - parameter to step: The next step in the path from the current location.
     
     - Returns: An **RGCardinals** object that describes what type of turn is needed to be taken.
     */
    private func getTurn(from currentLocation: (Int, Int), to step: (Int, Int)) -> RGCardinals {
        let currentLocationRow = currentLocation.1
        let currentLocationColumn = currentLocation.0
        
        let stepRow = step.1
        let stepColumn = step.0
        
        if stepRow == currentLocationRow - 1 {
            return .south
        } else if stepRow == currentLocationRow + 1 {
            return .north
        }
        
        if stepColumn == currentLocationColumn - 1 {
            return .west
        } else if stepColumn == currentLocationColumn + 1 {
            return .east
        }
        
        return .north
    }
    
    /**
     A function that checks if device is in the limits of the node.
     
     - parameter nodePosition: The position of the node to be checked for.
     - parameter cameraPosition: The camera position from the AR scene view.
     - parameter offset: The offset of the limits.
     
     - Returns: **true** if it is in limits, **false** otherwise.
     */
    private func isInLimits(nodePosition: SCNVector3, cameraPosition: SCNVector3, offset: Float) -> Bool {
        return isInLimits(nodePosition.x, cameraPosition.x, offset) && isInLimits(nodePosition.y, cameraPosition.y, offset) && isInLimits(nodePosition.z, cameraPosition.z, offset)
    }
    
    /**
     Check if it is in limits based on 2 values and an offset.
     */
    private func isInLimits(_ val1: Float, _ val2: Float, _ offset: Float) -> Bool {
        return val1 - offset < val2 && val1 + offset > val2
    }
}
