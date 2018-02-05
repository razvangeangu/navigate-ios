//
//  BLEServiceProperties.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 05/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import CoreBluetooth

extension BLEService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("central.state is .poweredOn")
            if serviceCBUUID != nil {
                centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        piPeripheral = peripheral
        piPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        piPeripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        if central.state == .poweredOn {
            print("Scanning for peripherals")
            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
        }
    }
}

extension BLEService: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
//                piPeripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write) {
//                self.writeCharacteristic = characteristic
            }
        }
    }
    
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
