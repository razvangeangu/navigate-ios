//
//  Util.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 07/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import UIKit

enum RGCardinals: Float {
    case north = 0
    case east = 90
    case south = 180
    case west = 270
}

enum RGTurn {
    case front
    case back
    case right
    case left
    case none
}

/**
 Commands available from the search bar.
 */
enum SecretCommands: String {
    case switchToDevMode = "chamber of secrets"
    case switchToProdMode = "cowboy"
}

/**
 Commands available for the external bluetooth device.
 */
enum RGCommands: String {
    case stopPi = "sudo shutdown now"
    case updateServer = "cd /root/navigate-server && git pull && forever restartall"
    case restartServer = "cd /root/navigate-server && forever restartall"
}

/**
 An enum used for Tiles from Core Data.
 */
enum CDTileType: String {
    case sample = "sample"
    case space = "space"
    case wall = "wall"
    case door = "door"
    case none = "none"
    case location = "location"
    case navigation = "navigation"
}

/**
 An enum used to define the application mode.
 */
enum AppMode {
    case dev
    case prod
}

// Credits: https://www.raywenderlich.com/80818/operator-overloading-in-swift-tutorial
extension CGPoint {
    public static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    public static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    public static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    public static func / (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x / right.x, y: left.y / right.y)
    }
    
    public static func * (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x * right.x, y: left.y * right.y)
    }
}

// Credits: https://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
    
    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
}

// Credits: https://medium.com/swiftly-swift/how-to-build-a-compass-app-in-swift-2b6647ae25e8
extension Double {
    var toRadians: Double { return self * .pi / 180 }
    var toDegrees: Double { return self * 180 / .pi }
}

extension CGFloat {
    var toRadians: CGFloat { return self * .pi / 180 }
    var toDegrees: CGFloat { return self * 180 / .pi }
}

extension Float {
    var toRadians: Float { return self * .pi / 180 }
    var toDegrees: Float { return self * 180 / .pi }
}

extension UIViewController {
    func presentAlert(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: completion)
    }
    
    func presentDialog(title: String, message: String, handler: @escaping ((UIAlertAction) -> Void), completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: handler))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: handler))

        self.present(alert, animated: true, completion: completion)
    }
}

extension Float {
    // http://texnotes.me/post/5/
    static func randomBetween(_ first: Float, and second: Float) -> Float {
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    }
}

/**
 Checks if text is one of the secret commands. See **SecretCommands** enum.
 
 - parameter text: Represents the text to be verified.
 - parameter completion: A void function that returns the secret command found.
 */
func checkForSecretCommands(text: String, completion: (SecretCommands) -> Void) {
    switch text.lowercased() {
    case SecretCommands.switchToDevMode.rawValue:
        do {
            completion(SecretCommands.switchToDevMode)
        }
    case SecretCommands.switchToProdMode.rawValue:
        do {
            completion(SecretCommands.switchToProdMode)
        }
    default:
        break
    }
}
