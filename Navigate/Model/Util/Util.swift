//
//  Util.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 07/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration

/**
 An enum describing the names of the classes from Core Data
 */
enum DataClasses: String {
    case tile = "Tile"
    case accessPoint = "AccessPoint"
    case floor = "Floor"
    case room = "Room"
    case cachedRecords = "CachedRecords"
}

extension Float {
    static var humanWalkingSpeed: Float = 1.39
}

/**
 An enum that represents the geographical cardinal points.
 */
enum RGCardinals: Float {
    case north = 0
    case east = 90
    case south = 180
    case west = 270
}

/**
 An enum describing the turns of the device.
 */
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

// Credits: https://stackoverflow.com/questions/26794703/swift-integer-conversion-to-hours-minutes-seconds
func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}

extension Array {
    func chunks(_ chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }
}

// Credits: https://stackoverflow.com/questions/31604428/download-in-background-in-swift
func beginBackgroundTask() -> UIBackgroundTaskIdentifier {
    return UIApplication.shared.beginBackgroundTask(expirationHandler: {})
}

func endBackgroundTask(taskID: UIBackgroundTaskIdentifier) {
    UIApplication.shared.endBackgroundTask(taskID)
}

// Creadits: https://dzone.com/articles/network-reachability-with-swift-1
func isNetworkReachable(with flags: SCNetworkReachabilityFlags) -> Bool {
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
    let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
    return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
}

/**
 A function that tests connectivity to the internet by processing a request to www.google.com.
 
 - Returns: A **Bool** value that is **true** if Internet connectivity has been found. False **otherwise**.
 */
func isReachable() -> Bool {
    guard let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com") else { return false }
    var flags = SCNetworkReachabilityFlags()
    SCNetworkReachabilityGetFlags(reachability, &flags)
    return isNetworkReachable(with: flags)
}

extension UIColor {
    static var rgBlue = UIColor.init(red: 25, green: 118, blue: 210, a: 1.0)
}
