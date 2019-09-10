//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VinciChatInfoViewController: UIViewController {
    
    let navigationBar = VinciTopMenuController(title: "Info")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    var thread: TSThread?
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    @objc public init(thread: TSThread) {
        super.init(nibName: nil, bundle: nil)
        self.thread = thread
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.backgroundColor
        
        // Do any additional setup after loading the view.
        view.addSubview(navigationBar.view)
        navigationBarTopConstraint = navigationBar.pinToTop()
        headerViewMaxHeight = navigationBar.maxBarHeight
        navigationBar.searchBarMode = .hidden
        
        if let topTitleView = navigationBar.topTitleView as? VinciTopMenuRowViewController {
            topTitleView.leftBarItems.append(UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(dismissViewController)))
            topTitleView.rightBarItems.append(UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(dismissViewController)))
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        view.addSubview(tableView)
        
        tableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
        tableView.autoPinEdge(.top, to: .bottom, of: navigationBar.view)
        
        //        searchResultsController.delegate = self
    }
    
    @objc func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension VinciChatInfoViewController : UITableViewDelegate {
    
}

extension VinciChatInfoViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if thread == nil {
            return 0
        }
        
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowIndex = indexPath.row
        
        switch rowIndex {
        case 0:
            
            let cell = VinciContactViewCell(style: .default, reuseIdentifier: "contactCell")
            OWSTableItem.configureCell(cell)
            
            cell.configure(thread: thread!)
            cell.selectionStyle = .none
            cell.hideChecker(animated: false)
            
            return cell
            
        case 1, 2:
            
            let cell = PhoneMobileCell(style: .default, reuseIdentifier: "PhoneMobileCell")
            OWSTableItem.configureCell(cell)
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

@objc class PhoneMobileCell: UITableViewCell {
    
    var typeLabel = UILabel()
    let numberLabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    public func reuseIdentifier() -> String {
        return "PhoneMobileCell"
    }
    
    @objc func configure() {
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        selectionStyle = .default
        backgroundColor = Theme.backgroundColor
        
        typeLabel.font = VinciStrings.tinyFont
        typeLabel.textColor = Theme.primaryColor
        typeLabel.text = "mobile"
        
        numberLabel.font = VinciStrings.regularFont
        numberLabel.textColor = UIColor.vinciBrandBlue
        numberLabel.text = "+7 000 0000 00 00"

        let topRowStack = UIStackView(arrangedSubviews: [typeLabel])
        topRowStack.axis = .horizontal
        topRowStack.alignment = .fill
        topRowStack.spacing = 0

        let bottomRowStack = UIStackView(arrangedSubviews: [numberLabel])
        bottomRowStack.axis = .horizontal
        bottomRowStack.alignment = .fill
        bottomRowStack.spacing = 0
    
        let vStack = UIStackView(arrangedSubviews: [topRowStack, bottomRowStack])
        vStack.axis = .vertical
        vStack.alignment = .fill
        vStack.spacing = 0
        
        self.contentView.addSubview(vStack)
        vStack.autoPinEdgesToSuperviewEdges()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessoryType = .none
    }
}
