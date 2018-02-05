//
//  ViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreData

class ViewController: UIViewController {
    var centralManager: CBCentralManager!
    var piPeripheral: CBPeripheral!
    let piServiceCBUUID = CBUUID(string: "0x12AB")
    let wifiCharacteristicCBUUID = CBUUID(string: "34CD")
    var writeCharacteristic: CBCharacteristic!
    var data: String = ""
    var json: Any! {
        didSet {
//             print(json)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        centralManager = CBCentralManager(delegate: self, queue: nil)
        
//        let floor = Floor(context: PersistenceService.context)
//        floor.level = 6
//        PersistenceService.saveContext()
        
        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        do {
            let floors = try PersistenceService.context.fetch(fetchRequest)
            for floor in floors {
                print(floor.level)
            }
        } catch {
            print("Error in Floor fetchRequest")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let command = "cd /usr/local/bin/server/ && git pull && forever restartall"
//        piPeripheral.writeValue(command.data(using: .utf8)!, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
//        print("Writing command: \(command)")
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: [piServiceCBUUID])
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
            centralManager.scanForPeripherals(withServices: [piServiceCBUUID])
        }
    }
}

extension ViewController: CBPeripheralDelegate {
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
//                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write) {
                self.writeCharacteristic = characteristic
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
