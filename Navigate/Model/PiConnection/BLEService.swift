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
    var shouldReturnData = false
    var json: Any! {
        didSet {
            RGSharedDataManager.jsonData = json
        }
    }
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /**
     Connect to an external device such as a Raspberry Pi.
     
     - parameter to: the CBUUID of the piService.
     */
    func connect(to piService: String) {
        serviceCBUUID = CBUUID(string: piService)
    }
    
    /**
     Disconnect the external device.
     */
    func disconnect() {
        if piPeripheral != nil {
            centralManager.cancelPeripheralConnection(piPeripheral)
        }
    }
    
    /**
     Write a command to the external device to be executed from the terminal.
     
     - parameter command: A string that represents a short command.
     */
    func write(command: String) {
        if writeCharacteristic != nil {
            piPeripheral.writeValue(command.data(using: .utf8)!, for: writeCharacteristic, type: .withResponse)
        }
    }
    
    /**
     Shutdown the external device.
     */
    func stopPi() {
        write(command: "sudo shutdown now")
    }
    
    /**
     Get the WiFi list from the external device.
     
     - Returns: A json object that contains a list of access points with uuid and strength.
     */
    func getWiFiList() -> Any? {
        if self.json != nil {
            return self.json
        }
        
        return {}
    }
}
