//
//  SheetViewControllerExtensions.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 15/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

extension SheetViewController {
    
    @objc func panGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        var y = self.view.frame.minY + translation.y
        
        if y < upperBound {
            y = upperBound
            
            tableView.isScrollEnabled = true
        } else if y > lowerBound {
            y = lowerBound
        } else {
            if tableView.contentOffset.y > 0 {
                y = upperBound
                tableView.isScrollEnabled = true
            } else {
                tableView.isScrollEnabled = false
            }
        }
        
        if !tableView.isScrollEnabled {
            self.view.frame = CGRect(x: 0, y: y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view != otherGestureRecognizer.view {
            return false
        }
        
        return true
    }
}
