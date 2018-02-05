//
//  BLEService.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 05/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreBluetooth

class BLEService: NSObject {
    var centralManager: CBCentralManager!
    var piPeripheral: CBPeripheral!
    var serviceCBUUID: CBUUID!
    let wifiCharacteristicCBUUID = CBUUID(string: "34CD")
    var writeCharacteristic: CBCharacteristic!
    var data: String = ""
    var json: Any! {
        didSet {
            // print(json)
        }
    }
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect(to piService: String) {
        // 0x12AB
        serviceCBUUID = CBUUID(string: piService)
    }
    
    func disconnect() {
        if piPeripheral != nil {
            centralManager.cancelPeripheralConnection(piPeripheral)
        }
    }
}
