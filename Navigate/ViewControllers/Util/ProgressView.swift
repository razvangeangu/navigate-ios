//
//  ProgressView.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 28/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class ProgressView: UIView {

    private var containerProgressView: UIView!
    private var progressView: UIProgressView!
    private var loadingLabel: UILabel!
    static var didFinishLoading = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initProgressView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Initialises and adds the progress view to the main view.
     */
    fileprivate func initProgressView() {
        
        // Initialise the container for the progress view
        containerProgressView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = containerProgressView.bounds
        blurEffectView.isUserInteractionEnabled = false
        containerProgressView.insertSubview(blurEffectView, at: 0)
        
        // Initiliase the progress view
        progressView = UIProgressView(frame: CGRect(x: 20, y: center.y, width: frame.width - 40, height: 10))
        containerProgressView.isUserInteractionEnabled = false
        containerProgressView.addSubview(progressView)
        
        // Adding loading label
        loadingLabel = UILabel(frame: CGRect(x: progressView.frame.minX, y: progressView.frame.minY - 40, width: progressView.frame.width, height: 20))
        loadingLabel.textAlignment = .center
        loadingLabel.text = "Updating data N/A"
        containerProgressView.addSubview(loadingLabel)
        
        // Add the progress view to the main view
        self.addSubview(containerProgressView)
        
        // Hide the container
        self.isHidden = true
    }
    
    /**
     A function that sets the progress to a specific value.
     
     - parameter to: The value to set the progress view to.
     */
    func setProgress(to value: Float) {
        DispatchQueue.main.async {
            if value >= 1.0 {
                self.isHidden = true
                ProgressView.didFinishLoading = true
                MapViewController.scene.view?.isUserInteractionEnabled = true
            } else {
                self.isHidden = false
                MapViewController.scene.view?.isUserInteractionEnabled = false
                self.progressView.setProgress(value, animated: true)
                self.loadingLabel.text = "Updating data \(Int(self.progressView.progress * 100))%"
                
                if !isReachable() {
                    if self.loadingLabel != nil {
                        self.loadingLabel.text = "Internet is needed to download the data."
                    }
                }
            }
        }
    }
    
    /**
     Adds value to the progress view.
     
     - parameter value: Value to be added to the progress.
     */
    func addToProgress(value: Float) {
        DispatchQueue.main.async {
            if value >= 1.0 {
                self.isHidden = true
                ProgressView.didFinishLoading = true
                MapViewController.scene.view?.isUserInteractionEnabled = true
            } else {
                self.isHidden = false
                MapViewController.scene.view?.isUserInteractionEnabled = false
                self.progressView.setProgress(self.progressView.progress + value, animated: true)
                self.loadingLabel.text = "Updating data \(Int(self.progressView.progress * 100))%"
            }
        }
    }
}
