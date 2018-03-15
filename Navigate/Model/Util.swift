//
//  Util.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 07/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import Foundation

enum Commands: String {
    case stopPi = "sudo shutdown now"
    case updateServer = "cd /root/navigate-server && git pull && forever restartall"
}

enum RGColor: String {
    case cyan = "cyan"
    case purple = "purple"
    case green = "green"
    case grey = "grey"
}

enum AccessPointType: String {
    case free = "free"
    case wall = "wall"
    case door = "door"
}
