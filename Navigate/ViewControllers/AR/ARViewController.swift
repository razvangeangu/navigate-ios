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
        xs.append(0)
        zs.append(0)
        
        let distance = RGSharedDataManager.tileLength
        
        var xLast: Float?
        var zLast: Float?
        for step in path {
            let x = Float(step.col)
            let z = Float(step.row)
            
            if xLast == nil || zLast == nil {
                xLast = x
                zLast = z
            }
            
            if x < xLast! {
                xs.append(-distance)
                zs.append(0)
            } else if x > xLast! {
                xs.append(distance)
                zs.append(0)
            } else {
                if z < zLast! {
                    zs.append(-distance)
                    xs.append(0)
                } else if x > zLast! {
                    zs.append(distance)
                    xs.append(0)
                }
            }
            
            xLast = x
            zLast = z
        }
        
        self.xs = xs
        self.zs = zs
    }
    
    func turn(from currentLocation: (Int, Int), to step: (Int, Int)) {
        
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
    
    internal func moveRing(to position: SCNVector3) {
        ringNode.position = position
        sceneView.scene.rootNode.addChildNode(ringNode)
    }
    
    internal func removeRing() {
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
        var cameraPosition = SCNVector3(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )
        
        if pos == 0 {
            if let heading = RGLocalisation.heading {
                let headingDegrees = CGFloat(heading).toDegrees
                let degrees: [CGFloat] = [0, 90, 180, 270]
                let degreesDifferences = degrees.map({abs($0 - headingDegrees)})
                let angle = degrees[degreesDifferences.index(of: degreesDifferences.min()!)!]
                var x = 0

                switch angle {
                case 0:
                    do {
                        x = 0
                    }
                case 90:
                    do {
                        x = -1
                    }
                case 180:
                    do {
                        x = 0
                    }
                case 270:
                    do {
                        x = 1
                    }
                default:
                    break
                }

                cameraPosition.x = Float(x)
            }
        }
        
        // Get the position in x y z in the scene view of the ring
        let nodePosition = SCNVector3(
            nodeTransform.m41,
            nodeTransform.m42,
            nodeTransform.m43
        )
        
        if xs != nil && zs != nil && !xs.isEmpty && !zs.isEmpty && pos != xs.count {
            if isInLimits(nodePosition: nodePosition, cameraPosition: cameraPosition, offset: 0.5) {
                
                // Give haptic feedback to the user
                generator.impactOccurred()
                
                moveRing(to: SCNVector3(x: cameraPosition.x + xs[pos], y: 0, z: cameraPosition.z + zs[pos]))
                pos += 1
            }
        }
    }
    
    internal func isInLimits(nodePosition: SCNVector3, cameraPosition: SCNVector3, offset: Float) -> Bool {
        return isInLimits(nodePosition.x, cameraPosition.x, offset) && isInLimits(nodePosition.y, cameraPosition.y, offset) && isInLimits(nodePosition.z, cameraPosition.z, offset)
    }
    
    internal func isInLimits(_ val1: Float, _ val2: Float, _ offset: Float) -> Bool {
        return val1 - offset < val2 && val1 + offset > val2
    }
}
