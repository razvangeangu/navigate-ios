//
//  AdminViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 17/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class AdminViewController: UIViewController {
    
    // UI Components Outlets
    @IBOutlet weak var floorLevelTextField: UITextField!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var addFloorButton: UIButton!
    @IBOutlet weak var addRoomButton: UIButton!
    @IBOutlet weak var loadFloorMapButton: UIButton!
    @IBOutlet weak var floorMapImageView: UIImageView!
    @IBOutlet weak var selectedFloorLabel: UILabel!
    
    // Image Picker Controller
    let imagePicker = UIImagePickerController()
    
    // Boolean to check if image has been picked
    var imagePicked = false
    
    // Parent View Controller
    var parentVC: MapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set style
        initBlurredBackground()
        initBackButton()
        
        // Set delegates
        setDelegates()
        
        // Display data for the label
        if let selectedFloor = RGSharedDataManager.floorLevel {
            selectedFloorLabel.text = "Selected floor: \(selectedFloor)"
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Close keyboard if touches the view
        view.endEditing(true)
    }
    
    /**
     Initialise the background with blur efect style.
     */
    fileprivate func initBlurredBackground() {
        view.backgroundColor = .clear

        let blurredView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurredView.frame = view.bounds
        blurredView.isUserInteractionEnabled = true
        view.insertSubview(blurredView, at: 0)
    }
    
    /**
     Set the delegates for this class.
    */
    fileprivate func setDelegates() {
        imagePicker.delegate = self
    }
    
    /**
     Initiliases the back button and adds it to the view.
    */
    fileprivate func initBackButton() {
        let backButton = RGBackButton(frame: CGRect(x: view.frame.minX + 20, y: view.frame.minY + 40, width: 40, height: 40))
        backButton.addTarget(self, action: #selector(AdminViewController.didPressBackButton), for: .touchUpInside)
        view.addSubview(backButton)
    }
    
    /**
     Dismisses the view controller with animation.
    */
    @objc func didPressBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Creates a new floor and adds it to CoreData.
     
     The floor text field must not be empty.
     Data in the picker view will be updated and textfield cleared if successful.
     It displays alerts for all cases.
     */
    @IBAction func didPressAddFloor(_ sender: Any) {
        if let floorLevelText = floorLevelTextField.text {
            if let floorLevel = Int(floorLevelText) {
                if imagePicked {
                    RGSharedDataManager.addFloor(level: floorLevel, mapImage: (UIImagePNGRepresentation(floorMapImageView.image!) as NSData?)!)
                    
                    parentVC.bottomSheetVC.updatePickerData()
                    presentAlert(title: "Success", message: "A floro has been created.", completion: {
                        self.floorLevelTextField.text = ""
                        self.floorMapImageView.contentMode = .scaleAspectFit
                        self.floorMapImageView.image = UIImage(named: "addimage")
                        self.imagePicked = false
                    })
                } else {
                    presentAlert(title: "Error", message: "An image map must be selected.", completion: nil)
                }
            } else {
                presentAlert(title: "Error", message: "Floor level cannot be empty.", completion: nil)
            }
        }
    }
    
    /**
     Creates a new room and adds it to CoreData.
     
     The room text field must not be empty and a floor should be selected in the map view.
     Data in the table view will be updated and textfield cleared if successful.
     It displays alerts for all cases.
     */
    @IBAction func didPressAddRoom(_ sender: Any) {
        if let roomName = roomNameTextField.text {
            if !roomName.isEmpty {
                if let _ = RGSharedDataManager.floor {
                    if let _ = RGSharedDataManager.getRoom(name: roomName, floor: RGSharedDataManager.floor) {
                        presentAlert(title: "Error", message: "Room name already exists.", completion: nil)
                    } else {
                        if RGSharedDataManager.addRoom(name: roomName) {
                            
                            parentVC.bottomSheetVC.updateTableData()
                            presentAlert(title: "Success", message: "A room has been created.") {
                                self.roomNameTextField.text = ""
                            }
                        }
                    }
                } else {
                    presentAlert(title: "Error", message: "Floor must be selected.", completion: nil)
                }
            } else {
                presentAlert(title: "Error", message: "Room name cannot be empty.", completion: nil)
            }
        }
    }
    
    /**
     Shows image picker to select image for the floor map.
     */
    @IBAction func didPressLoadFloorMap(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil)
    }
}

extension AdminViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // If selected image
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Set the style
            floorMapImageView.contentMode = .scaleAspectFit
            
            // Set the image
            floorMapImageView.image = pickedImage
            
            // Announce controllers
            imagePicked = true
        }
        
        // Dismiss the image picker controller
        dismiss(animated: true, completion: nil)
    }
}
