//
//  AdminViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 17/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit
import Photos

class AdminViewController: UIViewController {
    
    // UI Components Outlets
    @IBOutlet weak var floorLevelTextField: UITextField!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var addFloorButton: UIButton!
    @IBOutlet weak var addRoomButton: UIButton!
    @IBOutlet weak var loadFloorMapButton: UIButton!
    @IBOutlet weak var floorMapImageView: UIImageView!
    @IBOutlet weak var selectedFloorLabel: UILabel!
    @IBOutlet weak var updateDataOnlineButton: UIButton!
    
    // Image Picker Controller
    let imagePicker = UIImagePickerController()
    
    // Picked image from the photo library
    var pickedImage: UIImage?
    
    // Boolean to check if image can be picked
    var shouldOpenPhotoLibrary = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set style
        initBlurredBackground()
        initBackButton()
        
        // Set delegates
        setDelegates()
        
        // Display data for the label
        selectedFloorLabel.text = "Selected floor: \(RGSharedDataManager.floor.level)"
        
        // Get permission for gallery
        requestPermissionForPhotoGallery()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // Close keyboard if touches the view
        view.endEditing(true)
    }
    
    /**
     Requests authorisation to access the photo gallery.
     */
    fileprivate func requestPermissionForPhotoGallery() {
        imagePicker.sourceType = .photoLibrary
        
        PHPhotoLibrary.requestAuthorization({
            (newStatus) in
            if newStatus == PHAuthorizationStatus.authorized {
                self.shouldOpenPhotoLibrary = true
            }
        })
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
        floorLevelTextField.delegate = self
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
                if let pickedImage = pickedImage {
                    if let imageData = UIImagePNGRepresentation(pickedImage) as NSData? {
                        
                        // Add floor
                        if RGSharedDataManager.addFloor(level: floorLevel, mapImage: imageData) {
                            
                            // Update the picker data
                            MapViewController.bottomSheetVC.updatePickerData()
                            
                            // Feedback
                            presentAlert(title: "Success", message: "A floor has been created.", completion: {
                                self.floorLevelTextField.text = ""
                                self.floorMapImageView.contentMode = .scaleAspectFit
                                self.floorMapImageView.image = UIImage(named: "addimage")
                                self.pickedImage = nil
                            })
                        } else {

                            presentDialog(title: "Error", message: "Floor already exists. Do you want to overwrite it?", handler: { (alertAction) in
                                if alertAction.title == "Ok" {
                                    
                                    // Remove the current floor
                                    if RGSharedDataManager.removeFloor(with: floorLevel) {
                                    
                                        // Add the floor
                                        if RGSharedDataManager.addFloor(level: floorLevel, mapImage: imageData) {
                                            
                                            // Update picker data
                                            MapViewController.bottomSheetVC.updatePickerData()
                                            
                                            // Feedback
                                            self.presentAlert(title: "Success", message: "A floor has been created.", completion: {
                                                self.floorLevelTextField.text = ""
                                                self.floorMapImageView.contentMode = .scaleAspectFit
                                                self.floorMapImageView.image = UIImage(named: "addimage")
                                                self.pickedImage = nil
                                            })
                                        } else {
                                            self.presentAlert(title: "Error", message: "Cannot add floor.", completion: nil)
                                        }
                                    } else {
                                        self.presentAlert(title: "Error", message: "Cannot remove floor.", completion: nil)
                                    }
                                }
                            }, completion: nil)
                        }
                    }
                } else {
                    presentAlert(title: "Error", message: "An image map must be selected.", completion: nil)
                }
            } else {
                presentAlert(title: "Error", message: "Floor level cannot be empty and must be a number.", completion: nil)
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
                
                checkForSecretCommands(text: roomName) { (result) in
                    self.presentAlert(title: "Error", message: "Cannot create room with special name.", completion: nil)
                }
                
                if let _ = RGSharedDataManager.floor {
                    // Add room
                    if RGSharedDataManager.addRoom(name: roomName) {
                        
                        // Update the table data
                        MapViewController.bottomSheetVC.updateTableData()
                        
                        // Feedback
                        presentAlert(title: "Success", message: "A room has been created.") {
                            self.roomNameTextField.text = ""
                        }
                    } else {
                        presentDialog(title: "Error", message: "A room with the same name already exists. Do you want to overwrite it?", handler: { (alertAction) in
                            if alertAction.title == "Ok" {
                                
                                // Remove room
                                if RGSharedDataManager.removeRoom(with: roomName, floor: RGSharedDataManager.floor) {
                                
                                    // Add room
                                    if RGSharedDataManager.addRoom(name: roomName) {
                                        
                                        // Update the table data
                                        MapViewController.bottomSheetVC.updateTableData()
                                        
                                        // Feedback
                                        self.presentAlert(title: "Success", message: "A room has been created.") {
                                            self.roomNameTextField.text = ""
                                        }
                                    } else {
                                        self.presentAlert(title: "Error", message: "Cannot add room.", completion: nil)
                                    }
                                } else {
                                    self.presentAlert(title: "Error", message: "Cannot remove room.", completion: nil)
                                }
                            }
                        }, completion: nil)
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
        if shouldOpenPhotoLibrary {
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            presentAlert(title: "Error", message: "Access to the photo gallery is required.") {
                self.requestPermissionForPhotoGallery()
                self.didPressLoadFloorMap(sender)
            }
        }
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
            
            // Set the picked image
            self.pickedImage = pickedImage
        }
        
        // Dismiss the image picker controller
        dismiss(animated: true, completion: nil)
    }
}

extension AdminViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Check if contains a plus / minus
        if range.location == 0 {
            if string == "+" || string == "-" {
                return true
            }
        }
        
        // Check if the replacement string is a digit
        if let _ = Int(string) {
            return true
        }
        
        // Check for deletion
        if string == "" {
            return true
        }
        
        return false
    }
}
