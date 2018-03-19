//
//  AdminViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 17/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class AdminViewController: UIViewController {
    
    @IBOutlet weak var floorLevelTextField: UITextField!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var addFloorButton: UIButton!
    @IBOutlet weak var addRoomButton: UIButton!
    @IBOutlet weak var loadFloorMapButton: UIButton!
    @IBOutlet weak var floorMapImageView: UIImageView!
    @IBOutlet weak var selectedFloorLabel: UILabel!
    
    var backButton: UIButton!
    let imagePicker = UIImagePickerController()
    var imagePicked = false
    
    var parentVC: MapViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initBackButton()
        
        setDelegates()
        
        if let selectedFloor = RGSharedDataManager.floorLevel {
            selectedFloorLabel.text = "Selected floor: \(selectedFloor)"
        }
        
        initBlurredBackground()
    }
    
    fileprivate func initBlurredBackground() {
        view.backgroundColor = .clear
        
        let blurredView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurredView.frame = view.bounds
        blurredView.isUserInteractionEnabled = true
        view.insertSubview(blurredView, at: 0)
    }
    
    fileprivate func setDelegates() {
        imagePicker.delegate = self
    }
    
    fileprivate func initBackButton() {
        let shadowView = UIView(frame: CGRect(x: view.frame.minX + 20, y: view.frame.minY + 40, width: 40, height: 40))
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 5.0
        
        let baseView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        baseView.layer.cornerRadius = 20
        baseView.layer.masksToBounds = true
        shadowView.addSubview(baseView)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = baseView.bounds
        blur.isUserInteractionEnabled = false
        baseView.insertSubview(blur, at: 0)

        backButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        backButton.setTitle("X", for: .normal)
        backButton.titleLabel?.font = backButton.titleLabel?.font.withSize(18)
        backButton.addTarget(self, action: #selector(AdminViewController.didPressBackButton), for: .touchUpInside)
        baseView.addSubview(backButton)
        
        view.addSubview(shadowView)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @objc func didPressBackButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
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
    
    @IBAction func didPressAddRoom(_ sender: Any) {
        if let roomName = roomNameTextField.text {
            if !roomName.isEmpty {
                if let _ = RGSharedDataManager.floor {
                    if let _ = RGSharedDataManager.getRoom(name: roomName) {
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
    
    @IBAction func didPressLoadFloorMap(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func presentAlert(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: completion)
    }
}

extension AdminViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            floorMapImageView.contentMode = .scaleAspectFit
            floorMapImageView.image = pickedImage
            imagePicked = true
        }
        
        dismiss(animated: true, completion: nil)
    }
}
