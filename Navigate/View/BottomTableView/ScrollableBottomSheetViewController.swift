//
//  ScrollableBottomSheetViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 16/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class ScrollableBottomSheetViewController: UIViewController {
    
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
    
    var isSearching = false
    
    var tableViewFilteredData = [String]()
    var tableViewData = [String]() {
        didSet {
            if tableViewData.count > 0 {
                tableView.reloadData()
            }
        }
    }
    
    var pickerData = [Int]() {
        didSet {
            pickerData.sort()
            pickerView.reloadAllComponents()
        }
    }
    
    static var status: String = "" {
        didSet {
            staticSelf.statusLabel.text = status
        }
    }
    
    static var staticSelf: ScrollableBottomSheetViewController!
    
    let fullView: CGFloat = 200
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - 100
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "DefaultTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(ScrollableBottomSheetViewController.panGesture))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        ScrollableBottomSheetViewController.staticSelf = self
        
        tableView.delaysContentTouches = false
        
        prepareBackgroundView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height - 100)
            })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareBackgroundView(){
        view.backgroundColor = .clear
        tableView.backgroundColor = .clear
        headerView.backgroundColor = .clear
        baseView.backgroundColor = .clear
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0.5, height: 4)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 5.0
        
        baseView.frame = view.bounds
        baseView.layer.cornerRadius = 10
        baseView.layer.masksToBounds = true
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = baseView.bounds
        blur.isUserInteractionEnabled = false
        baseView.insertSubview(blur, at: 0)
        
        dragIndicatorView.layer.cornerRadius = 3
        dragIndicatorView.layer.masksToBounds = true
        
        statusLabel.textColor = UIColor.gray
        statusLabel.text = "Status"
        
        if RGSharedDataManager.appMode == .dev {
            // add room button
            let addButton = UIButton(frame: CGRect(x: searchBar.frame.maxX - 48, y: 24, width: 48, height: 48))
            addButton.setTitle("+", for: .normal)
            addButton.setTitleColor(.init(red: 25, green: 118, blue: 210, a: 1.0), for: .normal)
            addButton.titleLabel?.font = addButton.titleLabel?.font.withSize(30)
            
            addButton.addTarget(self, action: #selector(ScrollableBottomSheetViewController.addButtonTaped), for: .touchUpInside)
            
            headerView.addSubview(addButton)

            searchBarWidthConstraint.constant -= 44
        }
    }
    
    @objc func addButtonTaped(_ sender: UIButton!) {
        parent?.performSegue(withIdentifier: "roomAdmin", sender: parent)
    }
    
    func updatePickerData() {
        if let floors = RGSharedDataManager.getFloors() {
            pickerData = floors.map({ Int($0.level) })
            
            if let row = pickerData.index(of: RGSharedDataManager.floorLevel) {
                pickerView.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }
    
    func updateTableData() {
        if let rooms = RGSharedDataManager.getRooms() {
            tableViewData = rooms.map({ (room) -> String in
                return room.name!
            })
        }
    }
}

extension ScrollableBottomSheetViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            isSearching = false
        } else {
            isSearching = true
            tableViewFilteredData = tableViewData.filter({ $0.lowercased().hasPrefix(searchText.lowercased()) })
        }
        
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
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
