//
//  MapTileEditViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 21/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class MapTileEditViewController: UIView {
    
    // The buttons view
    var baseView: UIView!
    
    // The selected type for tiles
    var selectedType: CDTileType! {
        didSet {
            RGSharedDataManager.tileType = selectedType
        }
    }
    
    let tileTypes: [CDTileType] = [.door, .wall, .space, .sample]
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: CGFloat(tileTypes.count) * 40))
        
        // Add shadow to the view
        backgroundColor = UIColor.clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5.0
        
        // Add base view
        addBaseView()
        
        // Add tile types buttons
        addTileTypes(tileTypes: tileTypes)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Adds the base view and set style blured.
     */
    fileprivate func addBaseView() {
        
        // Initiliase the buttons view
        baseView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height))
        
        // Round the corners
        baseView.layer.cornerRadius = 10
        baseView.layer.masksToBounds = true
        
        // Add the blur effect style
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = baseView.bounds
        blur.isUserInteractionEnabled = false
        baseView.insertSubview(blur, at: 0)
        
        
        // Add it to the view
        self.addSubview(baseView)
    }
    
    /**
     
     */
    fileprivate func addTileTypes(tileTypes: [CDTileType]) {
        var i: Int = 0
        while i < tileTypes.count {
            let tileTypeButton = UIButton(frame: CGRect(x: 0, y: 40 * i, width: 40, height: 40))
            let tileTypeImage = UIImage(named: tileTypes[i].rawValue)
            tileTypeButton.setBackgroundImage(tileTypeImage, for: .normal)
            tileTypeButton.tag = i
            tileTypeButton.addTarget(self, action: #selector(didPressTileTypeButton), for: .touchUpInside)
            baseView.addSubview(tileTypeButton)
            
            let separator = UIView(frame: CGRect(x: 0, y: tileTypeButton.frame.height * CGFloat(i + 1), width: tileTypeButton.frame.width, height: 1))
            separator.backgroundColor = .init(red: 216, green: 216, blue: 216, a: 1.0)
            
            if i != tileTypes.count {
                baseView.addSubview(separator)
            }
            
            i += 1
        }
    }
    
    /**
     */
    @objc func didPressTileTypeButton(_ sender: UIButton) {
        for case let v as UIButton in baseView.subviews {
            v.setTitle("", for: .normal)
        }
        
        sender.setTitle("•", for: .normal)
        
        self.selectedType = tileTypes[sender.tag]
        if RGSharedDataManager.appMode == .prod {
            MapViewController.devLog(data: "\"\(self.selectedType.rawValue)\" selected tile type.")
        } else {
            MapViewController.devLog(data: "\"\(self.selectedType.rawValue)\" selected tile type.")
        }
    }
}
