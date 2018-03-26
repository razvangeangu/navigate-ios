//
//  ScrollableBottomSheetViewControllerExtensions.swift
//  Navigate
//
//  https://github.com/AhmedElassuty/BottomSheetController
//  Modified by Răzvan-Gabriel Geangu on 16/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

extension ScrollableBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Number of sections for the table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of rows in the section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // If it is searching count the number of rows in the filtered data array
        if isSearching {
            return tableViewFilteredData.count
        }
        
        // Otherwise count the number of rows in the normal data array
        return tableViewData.count
    }
    
    // Height for rows
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // Reusable cell style and data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default")!
        
        // If it is searching get the data from the filtered data array
        if isSearching {
            cell.textLabel?.text = tableViewFilteredData[indexPath.row]
        
        // Otherwise get the data from the normal data array
        } else {
            cell.textLabel?.text = tableViewData[indexPath.row]
        }
        
        return cell
    }
    
    // Reset the selected row visual
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let selectedRow = self.indexPathForSelectedRow {
            if let selectedCell = tableView.cellForRow(at: selectedRow) {
                selectedCell.accessoryType = .none
                tableView.deselectRow(at: selectedRow, animated: true)
            }
        }
        
        return indexPath
    }
    
    // Select and update the model
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)!
        let selectedRoomName: String!
        
        // If it is searching get the data from the filtered data array
        if isSearching {
            selectedRoomName = tableViewFilteredData[indexPath.row]
            
        // Otherwise get the data from the normal data array
        } else {
            selectedRoomName = tableViewData[indexPath.row]
        }
        
        // Select the room and move to the location
        RGSharedDataManager.selectedRoom = selectedRoomName
        
        // Add visual feedback for the selected cell
        selectedCell.accessoryType = .checkmark
        self.indexPathForSelectedRow = indexPath
        tableView.deselectRow(at: indexPath, animated: true)

        // Feedback to the log
        MapViewController.prodLog("\(RGSharedDataManager.selectedRoom ?? "N/A") selected")
    }
}

extension ScrollableBottomSheetViewController: UIGestureRecognizerDelegate {
    
    // Disable simultaneously recognition of the gestures to allow scroll for the view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let gesture = (gestureRecognizer as! UIPanGestureRecognizer)
        let direction = gesture.velocity(in: view).y
        
        let y = view.frame.minY
        if (y == fullView && tableView.contentOffset.y == 0 && direction > 0) || (y == partialView) {
            tableView.isScrollEnabled = false
        } else {
            tableView.isScrollEnabled = true
        }
        
        return false
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)
        
        view.endEditing(true)
        
        let y = self.view.frame.minY
        if (y + translation.y >= fullView) && (y + translation.y <= partialView) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
                }
                
                self.view.endEditing(true)
                
            }, completion: { [weak self] _ in
                if ( velocity.y < 0 ) {
                    self?.tableView.isScrollEnabled = true
                }
            })
        }
    }
}

extension ScrollableBottomSheetViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        // Remove the picker view line separators
        pickerView.subviews.forEach({ $0.isHidden = $0.frame.height < 1.0 })
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        // Count the number of elements in the picker data array
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        // Return data from the picker data array
        return "\(pickerData[row])"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        // Set the floor to the picked row
        RGSharedDataManager.setFloor(level: pickerData[row])
        
        // Deselect row and room
        if let selectedRow = self.indexPathForSelectedRow {
            if let selectedCell = tableView.cellForRow(at: selectedRow) {
                selectedCell.accessoryType = .none
                tableView.deselectRow(at: selectedRow, animated: true)
            }
        }
        
        // Update table data when floor is changed
        updateTableData()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var labelToReturn: UILabel!
        
        // Set the label visually
        if let view = view as? UILabel { labelToReturn = view } else { labelToReturn = UILabel() }
        labelToReturn.text = "\(pickerData[row])"
        labelToReturn.textColor = .gray
        labelToReturn.textAlignment = .center
        
        return labelToReturn
    }
}

extension ScrollableBottomSheetViewController: UISearchBarDelegate {
    
    // Set the filtered data
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // Activate secret command if matches raw value
        checkForSecretCommands(text: searchText) { (result) in
            if result == .switchToProdMode {
                RGSharedDataManager.appMode = .prod
                searchBar.text = ""
                isSearching = false
                tableView.reloadData()
            } else if result == .switchToDevMode {
                RGSharedDataManager.appMode = .dev
                searchBar.text = ""
                isSearching = false
                tableView.reloadData()
            }
        }
        
        if searchText.isEmpty || (searchBar.text?.isEmpty)! {
            isSearching = false
            
            tableView.reloadData()
        } else {
            isSearching = true
            
            // Filter the data lowercased
            tableViewFilteredData = tableViewData.filter({ $0.lowercased().hasPrefix(searchText.lowercased()) })
        }
    }
    
    // If the search bar button is clicked, dismiss the keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    // Move the view to top when editing started
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if self.view.frame.minY != self.fullView {
            UIView.animate(withDuration: 0.24, animations: { [weak self] in
                let frame = self?.view.frame
                let yComponent = self?.fullView
                self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height)
            })
        }
    }
}
