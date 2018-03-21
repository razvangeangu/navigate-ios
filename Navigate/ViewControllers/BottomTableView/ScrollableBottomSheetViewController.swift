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
    @IBOutlet weak var searchBarWidthConstraint: NSLayoutConstraint!
    
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
            staticSelf.statusLabel.text = status
        }
    }
    
    // Static self used to update UI
    internal static var staticSelf: ScrollableBottomSheetViewController!
    
    // Used for the scrollable view
    internal let fullView: CGFloat = 200
    internal var partialView: CGFloat {
        return UIScreen.main.bounds.height - 100
    }

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
        
        // Animate the view from the bottom
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
        })
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
                searchBarWidthConstraint.constant -= (addButton.frame.width - 4)
            }
        }
    }
    
    func removeDevButton() {
        if viewIfLoaded != nil {
            if addButton.superview != nil {
                searchBarWidthConstraint.constant += (addButton.frame.width - 4)
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
        baseView.frame = view.bounds
        baseView.layer.cornerRadius = 10
        baseView.layer.masksToBounds = true
        
        // Add blur effect view
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = baseView.bounds
        blur.isUserInteractionEnabled = false
        baseView.insertSubview(blur, at: 0)
        
        // Add the drag indicator
        dragIndicatorView.layer.cornerRadius = 3
        dragIndicatorView.layer.masksToBounds = true
        
        // Change status label style
        statusLabel.textColor = UIColor.gray
        statusLabel.text = "Status"
        
        // set style for room button
        addButton = UIButton(frame: CGRect(x: searchBar.frame.maxX - 48, y: 24, width: 48, height: 48))
        addButton.setTitle("+", for: .normal)
        addButton.setTitleColor(.init(red: 25, green: 118, blue: 210, a: 1.0), for: .normal)
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
            
            if let row = pickerData.index(of: Int(RGSharedDataManager.floor.level)) {
                pickerView.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }
    
    /**
     Updates the table data with the data from the shared data manager.
    */
    func updateTableData() {
        if let rooms = RGSharedDataManager.getRooms() {
            tableViewData = rooms.map({ (room) -> String in
                return room.name!
            })
        }
    }
}