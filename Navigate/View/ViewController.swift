//
//  ViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 01/02/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let ble = BLEService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // ble.connect(to: "0x12AB")
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
        
        // CoreData example
        //        let floor = Floor(context: PersistenceService.context)
        //        floor.level = 6
        //        PersistenceService.saveContext()
        
        //        let fetchRequest : NSFetchRequest<Floor> = Floor.fetchRequest()
        //        do {
        //            let floors = try PersistenceService.context.fetch(fetchRequest)
        //            for floor in floors {
        //                print(floor.level)
        //            }
        //        } catch {
        //            print("Error in Floor fetchRequest")
        //        }
    }
}


