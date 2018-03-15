//
//  Util.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 07/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

/**
 Commands available for the external bluetooth device.
 */
enum Commands: String {
    case stopPi = "sudo shutdown now"
    case updateServer = "cd /root/navigate-server && git pull && forever restartall"
}

/**
 RGColor is a enum used for tile colors.
 */
enum TileColor: String {
    case cyan = "cyan"
    case purple = "purple"
    case green = "green"
    case grey = "grey"
}

/**
 TileType is an enum for tile types.
 */
enum TileType: String {
    case free = "free"
    case wall = "wall"
    case door = "door"
}

enum AppMode {
    case dev
    case prod
}
