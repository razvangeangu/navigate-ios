//
//  SheetViewController.swift
//  Navigate
//
//  Created by Răzvan-Gabriel Geangu on 15/03/2018.
//  Copyright © 2018 Răzvan-Gabriel Geangu. All rights reserved.
//

import UIKit

class SheetViewController: UITableViewController, UIGestureRecognizerDelegate {
    
    let lowerBound: CGFloat = UIScreen.main.bounds.height - 150
    let upperBound: CGFloat = 300
    
    private var data = NSMutableArray(capacity: 100)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(SheetViewController.panGesture))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        
        for i in 0...99 {
            data.add(i)
        }
        
        tableView.isScrollEnabled = false
        
        self.tableView.register(RGTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.register(RGSearchTableViewCell.self, forCellReuseIdentifier: "searchCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.lowerBound
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height)
        }
    }
    
    func prepareBackgroundView(){
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = UIScreen.main.bounds
        
        tableView.backgroundColor = .clear
        tableView.backgroundView = blurView
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50
        }
        
        return 40
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.backgroundColor = .clear
        
        if indexPath.row == 0 {
            let searchCell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
            
            return searchCell
        } else {
            cell.textLabel?.text = "\(data[indexPath.row])"
        }
        
        return cell
    }
}
