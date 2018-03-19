//
//  Util.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 07/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation
import UIKit

/**
 Commands available for the external bluetooth device.
 */
enum RGCommands: String {
    case stopPi = "sudo shutdown now"
    case updateServer = "cd /root/navigate-server && git pull && forever restartall"
    case restartServer = "cd /root/navigate-server && forever restartall"
}

/**
 An enum used for tile types.
 */
enum RGTileType {
    case saved
    case sample
    case location
    case none
}

/**
 An enum used to define the application mode.
 */
enum AppMode {
    case dev
    case prod
}
