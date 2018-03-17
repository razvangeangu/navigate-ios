//
//  ScrollableBottomSheetViewController.swift
//  BottomSheet
//
//  Created by Ahmed Elassuty on 10/15/16.
//  Copyright © 2016 Ahmed Elassuty. All rights reserved.
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
    @IBOutlet weak var searchBarWidthConstraint: NSLayoutConstraint!
    
    
    
    var data = [String]() {
        didSet {
            tableView.reloadData()
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
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "DefaultTableViewCell", bundle: nil), forCellReuseIdentifier: "default")
        
        searchBar.isUserInteractionEnabled = false
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(ScrollableBottomSheetViewController.panGesture))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        
        ScrollableBottomSheetViewController.staticSelf = self
        
        tableView.delaysContentTouches = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
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
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: self.view)
        let velocity = recognizer.velocity(in: self.view)

        let y = self.view.frame.minY
        if (y + translation.y >= fullView) && (y + translation.y <= partialView) {
            self.view.frame = CGRect(x: 0, y: y + translation.y, width: view.frame.width, height: view.frame.height)
            recognizer.setTranslation(CGPoint.zero, in: self.view)
        }
        
        if recognizer.state == .ended {
            var duration =  velocity.y < 0 ? Double((y - fullView) / -velocity.y) : Double((partialView - y) / velocity.y )
            
            duration = duration > 1.3 ? 1 : duration
            
            UIView.animate(withDuration: duration, delay: 0.0, options: [.allowUserInteraction], animations: {
                if  velocity.y >= 0 {
                    self.view.frame = CGRect(x: 0, y: self.partialView, width: self.view.frame.width, height: self.view.frame.height)
                } else {
                    self.view.frame = CGRect(x: 0, y: self.fullView, width: self.view.frame.width, height: self.view.frame.height)
                }
                
                self.view.endEditing(true)
                self.searchBar.isUserInteractionEnabled = false
                
                }, completion: { [weak self] _ in
                    if ( velocity.y < 0 ) {
                        self?.tableView.isScrollEnabled = true
                        self?.searchBar.isUserInteractionEnabled = true
                    }
            })
        }
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
            
            addButton.addTarget(self, action: #selector(ScrollableBottomSheetViewController.addButtonTaped), for: .touchDown)
            
            headerView.addSubview(addButton)

            searchBarWidthConstraint.constant -= 44
        }
    }
    
    @objc func addButtonTaped(_ sender: UIButton!) {
        parent?.performSegue(withIdentifier: "roomAdmin", sender: parent)
    }
}
