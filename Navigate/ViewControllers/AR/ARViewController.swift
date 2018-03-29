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
    
    func updatePath(to path: [Tile]) {
        var xs = [Float]()
        var zs = [Float]()
        
        var previousStep = (0, 0)
        for step in path.reversed() {
            let x = Int(step.col)
            let z = Int(step.row)
            
            if xs.count == 0 && zs.count == 0 {
                xs.append(0)
                zs.append(0)
                
                previousStep = (x, z)
                
                continue
            }
            
            let nextStep = getNextStep(from: previousStep, to: (x, z))
            
            xs.append(Float(nextStep.1))
            zs.append(Float(nextStep.0))
            
            previousStep = (x, z)
        }
        
        self.xs = xs
        self.zs = zs
    }
    
    private func getNextStep(from currentLocation: (Int, Int), to step: (Int, Int)) -> (Int, Int) {
        var x: Int!
        var z: Int!
        
        let currentLocationRow = currentLocation.1
        let currentLocationColumn = currentLocation.0

        let stepRow = step.1
        let stepColumn = step.0
        
        let distance = Int(RGSharedDataManager.tileLength)

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
    
    fileprivate func initBackButton() {
        let backButton = RGBackButton(frame: CGRect(x: view.frame.minX + 20, y: view.frame.minY + 40, width: 40, height: 40))
        backButton.addTarget(self, action: #selector(ARViewController.didPressBackButton), for: .touchUpInside)
        view.addSubview(backButton)
    }
    
    @objc func didPressBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ARViewController {
    
    fileprivate func moveRing(to position: SCNVector3) {
        ringNode.position = position
        sceneView.scene.rootNode.addChildNode(ringNode)
    }
    
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
        
        if xs != nil && zs != nil && !xs.isEmpty && !zs.isEmpty && pos < xs.count {
            if isInLimits(nodePosition: nodePosition, cameraPosition: cameraPosition, offset: 0.5) {
                
                // Give haptic feedback to the user
                generator.impactOccurred()
                
                moveRing(to: SCNVector3(x: cameraPosition.x + xs[pos], y: 0, z: cameraPosition.z + zs[pos]))
                
                // To move 3m because tile size is 1.5m
                pos += 2
                
                let currentTile = RGNavigation.shortestPath?.reversed()[pos]
                RGLocalisation.currentLocation = (Int(currentTile!.col), Int(currentTile!.row))
            }
        } else if pos == xs.count {
            removeRing()
            self.presentAlert(title: "Success", message: "Arrived at the destination") {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func turn() {
        if let heading = RGLocalisation.heading {
            let headingDegrees = abs(heading.toDegrees)
            let degrees: [RGCardinals] = [RGCardinals.north, RGCardinals.east, RGCardinals.south, RGCardinals.west]
            let degreesDifferences = degrees.map({ abs($0.rawValue - headingDegrees) })
            let angle = degrees[degreesDifferences.index(of: degreesDifferences.min()!)!]
            
            if let shortestPath = RGNavigation.shortestPath {
                let currentStep = shortestPath[shortestPath.count - 1]
                let nextStep = shortestPath[shortestPath.count - 2]
                
                let currentLocation = (Int(currentStep.col), Int(currentStep.row))
                let nextLocation = (Int(nextStep.col), Int(nextStep.row))
                let turn = getTurn(from: currentLocation, to: nextLocation)
                
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
    
    private func isInLimits(nodePosition: SCNVector3, cameraPosition: SCNVector3, offset: Float) -> Bool {
        return isInLimits(nodePosition.x, cameraPosition.x, offset) && isInLimits(nodePosition.y, cameraPosition.y, offset) && isInLimits(nodePosition.z, cameraPosition.z, offset)
    }
    
    private func isInLimits(_ val1: Float, _ val2: Float, _ offset: Float) -> Bool {
        return val1 - offset < val2 && val1 + offset > val2
    }
}
