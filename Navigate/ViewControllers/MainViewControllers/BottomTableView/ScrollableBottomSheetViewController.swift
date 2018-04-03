//
//  ScrollableBottomSheetViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 16/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class ScrollableBottomSheetViewController: UIViewController {
    
    // UI components as outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var dragIndicatorView: UIView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var devSeparatorView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var searchBarLeadingConstraint: NSLayoutConstraint!
    
    var addButton: UIButton!

    // Tells if user is using the search bar to filter/search for data.
    internal var isSearching = false
    
    // The data for the table view
    internal var tableViewFilteredData = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    internal var tableViewData = [String]() {
        // Reload the data of the view when set
        didSet {
            tableViewData.sort()
            searchBar(searchBar, textDidChange: searchBar.text ?? "")
            tableView.reloadSections([0], with: .fade)
        }
    }
    internal var indexPathForSelectedRow: IndexPath?
    
    // The data for the picker view
    internal var pickerData = [Int]() {
        didSet {
            pickerData.sort()
            pickerView.reloadAllComponents()
        }
    }
    
    // The status that displays the log for dev and prod
    static var status: String = "" {
        // Reload the view when the status is changed
        didSet {
            if staticSelf != nil && staticSelf.statusLabel != nil {
                DispatchQueue.main.async {
                    staticSelf.statusLabel.text = status
                }
            }
        }
    }
    
    // Static self used to update UI
    private static var staticSelf: ScrollableBottomSheetViewController!
    
    // Used for the scrollable view
    let fullView: CGFloat = 200
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - 100
    }
    
    private var viewDidInit = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate for the search bar
        searchBar.delegate = self
        
        // Initialise and set the delegate for the table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        tableView.register(UINib(nibName: "DefaultTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        
        // Initialise and set the delegate for the picker view
        pickerView.delegate = self
        pickerView.dataSource = self
        
        // Add pan gesture for for the scrollable view
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(ScrollableBottomSheetViewController.panGesture))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // Initialise the static self
        ScrollableBottomSheetViewController.staticSelf = self
        
        // Prepare the view
        prepareBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if view.superview != nil && !viewDidInit {
            // Animate the view from the bottom
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                let frame = self?.view.frame
                let yComponent = self?.partialView
                self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
            })
            
            viewDidInit = true
        }
    }
    
    /**
     Adds the dev button **+** that performs segue to the control panel for the floor and rooms.
     */
    func addDevButton() {
        if viewIfLoaded != nil {
            if addButton.superview == nil {
                // Add it to the header view
                headerView.addSubview(addButton)
            
                // Fix constraint for the search bar
                searchBarLeadingConstraint.constant += (addButton.frame.width - 4)
            }
        }
    }
    
    /**
     A function that removes the dev button from the view and fixes the constraints.
     */
    func removeDevButton() {
        if viewIfLoaded != nil {
            if addButton.superview != nil {
                searchBarLeadingConstraint.constant -= (addButton.frame.width - 4)
                addButton.removeFromSuperview()
            }
        }
    }
    
    /**
     Performs segue to the room control view.
     */
    @objc func addButtonTaped(_ sender: UIButton!) {
        parent?.performSegue(withIdentifier: "roomAdmin", sender: parent)
    }
    
    /**
     Initiliases the view with all the components and manipulates the style.
     */
    fileprivate func prepareBackgroundView() {
        
        // Make all views transparent
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        headerView.backgroundColor = .clear
        baseView.backgroundColor = .clear
        
        // Add shadow to the main view
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0.5, height: 4)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 5.0
        
        // Round the corners
        baseView.frame = view.frame
        baseView.layer.cornerRadius = 10
        baseView.layer.masksToBounds = true
        
        // Add blur effect view
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = CGRect(x: 0, y: 0, width: (parent?.view.frame.width)!, height: baseView.frame.height)
        blur.isUserInteractionEnabled = false
        baseView.insertSubview(blur, at: 0)
        
        // Add the drag indicator
        dragIndicatorView.layer.cornerRadius = 3
        dragIndicatorView.layer.masksToBounds = true
        
        // Change status label style
        statusLabel.textColor = UIColor.gray
        statusLabel.text = "Status"
        
        // set style for room button
        addButton = UIButton(frame: CGRect(x: (parent?.view!.frame.width)! - 48 - searchBarLeadingConstraint.constant / 2, y: 24, width: 48, height: 48))
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(UIColor.rgBlue, for: .normal)
        addButton.titleLabel?.font = addButton.titleLabel?.font.withSize(30)
        addButton.addTarget(self, action: #selector(ScrollableBottomSheetViewController.addButtonTaped), for: .touchUpInside)
    }
    
    /**
     Updates the picker data with the data from the shared data manager and
     selects the row for the current floor level.
     */
    func updatePickerData() {
        if let floors = RGSharedDataManager.getFloors() {
            pickerData = floors.map({ Int($0.level) })
            
            if let floor = RGSharedDataManager.floor {
                let floorLevel = Int(floor.level)
                
                if let row = pickerData.index(of: floorLevel) {
                    pickerView.selectRow(row, inComponent: 0, animated: false)
                }
            }
        }
    }
    
    /**
     Updates the table data with the data from the shared data manager.
     */
    func updateTableData() {
        if let rooms = RGSharedDataManager.getRooms() {
            var roomsNames = rooms.map({ (room) -> String in
                return room.name!
            })
            if let indexOfSample = roomsNames.index(of: "SAMPLE") {
                roomsNames.remove(at: indexOfSample)
            }
            tableViewData = roomsNames
        }
    }
    
    /**
     Add a loading animation to the drag indicator.
     */
    func addLoadingAnimation() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, delay: 0, options: [.repeat, .allowUserInteraction, .autoreverse], animations: {
                self.dragIndicatorView.backgroundColor = UIColor.rgBlue
            }, completion: nil)
        }
    }
    
    /**
     Remove the loading animation from the drag indicator.
     */
    func removeLoadingAnimation() {
        dragIndicatorView.layer.removeAllAnimations()
        UIView.animate(withDuration: 1.0, delay: 0, options: [.allowUserInteraction], animations: {
            self.dragIndicatorView.backgroundColor = UIColor.init(red: 214, green: 214, blue: 214, a: 1.0)
        }, completion: nil)
    }
}
