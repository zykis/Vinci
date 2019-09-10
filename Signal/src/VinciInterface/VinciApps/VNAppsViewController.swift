//
//  VNAppsViewController.swift
//  TestTabbedNavigationWithLargeTitles
//
//  Created by Илья on 05/08/2019.
//  Copyright © 2019 Илья. All rights reserved.
//

import UIKit

class VNAppsViewController: VinciViewController {
    
    // MARK: Title Views
    var chatsTitleSize:CGSize?
    var spacesTitleSize:CGSize?
    var groupsTitleSize:CGSize?
    
    var chatsLargeTitleSize:CGSize?
    var spacesLargeTitleSize:CGSize?
    var groupsLargeTitleSize:CGSize?
    
    let selfTitle = "Vinci Apps"
    
    // MARK: G U I
    var searchController: UISearchController!
    var tableView: UITableView!
    var tableViewTopConstraint: NSLayoutConstraint!
    
    @objc enum VNAppsViewMode:Int {
        case chatsViewMode_Chats
        case chatsViewMode_Groups
    }
    
    var chatsViewMode = VNAppsViewMode.chatsViewMode_Chats
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    func commonInit() {
        searchController = UISearchController(searchResultsController: nil)
        tableView = UITableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        //        searchController.searchBar.placeholder = "search apps"
        //        searchController.searchBar.isTranslucent = false
        //        searchController.searchBar.isHidden = true
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        
        tableViewTopConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
        tableViewTopConstraint.isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        tableView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //        navigationItem.hidesSearchBarWhenScrolling = true
        navigationItem.title = selfTitle
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.bringSubview(toFront: view)
        
        tableView.reloadData()
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
//    @objc func handleTapOnLabel(tapGesture recognizer: UITapGestureRecognizer) {
//        //        print("title label tapped!")
//        let locationPoint = recognizer.location(in: recognizer.view)
//
//        let chatsRect = CGRect(x: 0, y: 0, width: chatsTitleSize!.width, height: chatsTitleSize!.height)
//        let groupsRect = CGRect(x: chatsTitleSize!.width + spacesTitleSize!.width, y: 0, width: groupsTitleSize!.width, height: groupsTitleSize!.height)
//
//        let chatsLargeRect = CGRect(x: 0, y: 0, width: chatsLargeTitleSize!.width, height: chatsLargeTitleSize!.height)
//        let groupsLargeRect = CGRect(x: chatsLargeTitleSize!.width + spacesLargeTitleSize!.width, y: 0, width: groupsLargeTitleSize!.width, height: groupsLargeTitleSize!.height)
//
//        if recognizer.view == smallTitle {
//            //            print("small title tapped!")
//            if chatsRect.contains(locationPoint) {
//                print("Chats Title tapped for sure!")
//                chatsViewMode = .chatsViewMode_Chats
//            } else if groupsRect.contains(locationPoint) {
//                print("Groups Title tapped for sure!")
//                chatsViewMode = .chatsViewMode_Groups
//            }
//        } else if recognizer.view == largeTitle {
//            //            print("large title tapped!")
//            if chatsLargeRect.contains(locationPoint) {
//                print("Chats Large Title tapped for sure!")
//                chatsViewMode = .chatsViewMode_Chats
//            } else if groupsLargeRect.contains(locationPoint) {
//                print("Groups Large Title tapped for sure!")
//                chatsViewMode = .chatsViewMode_Groups
//            }
//        }
//
//        applyColorStyle(toLabels: findTitleLabels())
//    }
    
}

extension VNAppsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension VNAppsViewController : UITableViewDelegate {
    
}
