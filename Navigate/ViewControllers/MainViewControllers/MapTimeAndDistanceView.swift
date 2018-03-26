//
//  MapTimeAndDistanceView.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 24/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class MapTimeAndDistanceView: UIView {
    
    // The buttons view
    var baseView: UIView!
    
    // The distance value for the navigation
    var distance: Float = 0 {
        didSet {
            distanceLabel.text = "\(Int(distance))m"
            time = distance / Float.humanWalkingSpeed
        }
    }
    
    // The time value for the navigation
    private var time: Float = 0 {
        didSet {
            let (h, m, s) = secondsToHoursMinutesSeconds(seconds: Int(time))
            var timeLabelText = ""
            if h != 0 {
                timeLabelText = "\(h)º "
            }
            
            if m != 0 {
                timeLabelText += "\(m)' "
            }
            
            if s != 0 {
                timeLabelText += "\(s)\""
            }
            
            timeLabel.text = timeLabelText
        }
    }
    
    // The information labels
    private var distanceLabel: UILabel!
    private var timeLabel: UILabel!
    
    // The close button view
    private var closeButtonView: UIView!
    private var closeButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: frame.minX, y: frame.minY, width: frame.width + 50, height: frame.height))
        
        // Add shadow to the view
        backgroundColor = UIColor.clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.5, height: 2)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5.0
        
        // Add the base view
        addBaseView()
        
        // Add the distance label
        addDistanceLabel()
        
        // Add the time label
        addTimeLabel()
        
        // Add close button
        addCloseButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Adds the base view and set style blured.
     */
    fileprivate func addBaseView() {
        // Initiliase the buttons view
        baseView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width - 50, height: self.bounds.height))
        
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
     Init and add distance label to the base view.
     */
    fileprivate func addDistanceLabel() {
        distanceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: baseView.frame.width / 2, height: baseView.frame.height / 2))
        distanceLabel.center.y = baseView.center.y
        distanceLabel.text = "/"
        distanceLabel.textAlignment = .center
        distanceLabel.textColor = .gray
        
        self.baseView.addSubview(distanceLabel)
    }
    
    /**
     Init and add time label to the base view.
     */
    fileprivate func addTimeLabel() {
        timeLabel = UILabel(frame: CGRect(x: distanceLabel.frame.width, y: 0, width: baseView.frame.width / 2, height: baseView.frame.height / 2))
        timeLabel.center.y = baseView.center.y
        timeLabel.text = "-"
        timeLabel.textAlignment = .center
        timeLabel.textColor = .gray
        
        self.baseView.addSubview(timeLabel)
    }
    
    /**
     Init and add close button to the base view.
     */
    fileprivate func addCloseButton() {
        // Initialise the close button view
        closeButtonView = UIView(frame: CGRect(x: baseView.frame.width + 10, y: frame.height / 4, width: 40, height: 40))
        closeButtonView.center.y = baseView.center.y
        closeButtonView.backgroundColor = UIColor.clear
        closeButtonView.layer.shadowColor = UIColor.black.cgColor
        closeButtonView.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        closeButtonView.layer.shadowOpacity = 0.2
        closeButtonView.layer.shadowRadius = 5.0
        
        // Add the blur effect style
        let blurView = UIView(frame: CGRect(x: 0, y: 0, width: closeButtonView.frame.width, height: closeButtonView.frame.height))
        blurView.layer.cornerRadius = closeButtonView.frame.width / 2
        blurView.layer.masksToBounds = true
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = closeButtonView.bounds
        blur.isUserInteractionEnabled = false
        blurView.insertSubview(blur, at: 0)
        closeButtonView.insertSubview(blurView, at: 0)
        
        // Add the close button
        let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: closeButtonView.frame.width, height: closeButtonView.frame.height))
        closeButton.setTitle("X", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.addTarget(self, action: #selector(didPressClose), for: .touchUpInside)
        closeButtonView.addSubview(closeButton)
        
        self.addSubview(closeButtonView)
    }
    
    /**
     The target method to be executed by the close button.
     
     - parameter sender: **Any** sender can take this action.
     */
    @objc func didPressClose(_ sender: Any) {
        MapViewController.shouldShowPath = false
        self.isHidden = true
    }
}
