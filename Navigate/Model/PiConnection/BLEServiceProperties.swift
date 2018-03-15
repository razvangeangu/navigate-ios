//
//  BLEServiceProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 05/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreBluetooth

extension BLEService: CBCentralManagerDelegate {
    
    // Power on the Bluetooth Low Energy Service
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            MapViewController.devLog(data: "central.state is .poweredOn")
            
            if serviceCBUUID != nil {
                
                MapViewController.devLog(data: "Scanning for peripherals")
                
                // Search for peripherals
                centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            }
        }
    }
    
    // If peripheral was discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Set the peripheral to the piService
        piPeripheral = peripheral
        piPeripheral.delegate = self
        
        // Stop the scanning
        centralManager.stopScan()
        
        // Connect to the service
        centralManager.connect(peripheral, options: nil)
    }
    
    // If connected to peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MapViewController.devLog(data: "Connected")
        
        // Get the services from the peripheral
        piPeripheral.discoverServices(nil)
    }
    
    // If the peripheral disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        MapViewController.devLog(data: "Disconnected")
        
        if central.state == .poweredOn {
            MapViewController.devLog(data: "Scanning for peripherals")
            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
        }
    }
}

extension BLEService: CBPeripheralDelegate {
    
    // Did discover services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            // Find characteristics
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Get .notify and .write characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                piPeripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write) {
                self.writeCharacteristic = characteristic
            }
        }
    }
    
    // Get the WiFi data from the .notify characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case wifiCharacteristicCBUUID:
            let chunkData = String(bytes: characteristic.value!, encoding: String.Encoding.utf8)!
            if (chunkData.contains("#")) {
                data.append(chunkData)
                data = String(data.dropLast("#".count))
                do {
                    json = try JSONSerialization.jsonObject(with: data.data(using: .utf8)!)
                } catch {
                    print(error)
                }
                data = ""
            } else {
                data.append(chunkData)
            }
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
}
