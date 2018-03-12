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
    var readCharacteristic: CBCharacteristic!
    var data: String = ""
    var shouldReturnData = false
    var json: Any! {
        didSet {
            print("Data Received..")
        }
    }
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect(to piService: String) {
        serviceCBUUID = CBUUID(string: piService)
    }
    
    func disconnect() {
        if piPeripheral != nil {
            centralManager.cancelPeripheralConnection(piPeripheral)
        }
    }
    
    func write(command: String) {
        if writeCharacteristic != nil {
            piPeripheral.writeValue(command.data(using: .utf8)!, for: writeCharacteristic, type: .withResponse)
        }
    }
    
    func stopPi() {
        write(command: "sudo shutdown now")
    }
    
    func read() {
        if readCharacteristic != nil {
            piPeripheral.readValue(for: readCharacteristic)
        }
    }
    
    func getWiFiList() -> Any {
        if self.json != nil {
            return self.json
        }
        
        return {}
    }
}
