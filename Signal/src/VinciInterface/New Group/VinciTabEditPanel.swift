//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

protocol VinciTabEditPanelDelegate {
    func readButtonPressed()
    func archiveButtonPressed()
    func deleteButtonPressed()
}

class VinciTabEditPanel: UIView {
    
    public let readButton = UIButton(type: .custom)
    public let archiveButton = UIButton(type: .custom)
    public let deleteButton = UIButton(type: .custom)
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var delegate:VinciTabEditPanelDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let editModeStack = UIStackView()
        editModeStack.axis = .horizontal
        editModeStack.distribution = .equalCentering
        
        readButton.setTitle("ReadAll", for: .normal)
        readButton.setTitleColor(Theme.primaryColor, for: .normal)
        
        archiveButton.setTitle("Archive", for: .normal)
        archiveButton.setTitleColor(Theme.primaryColor, for: .normal)
        
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(Theme.primaryColor, for: .normal)
        
        readButton.addTarget(self, action: #selector(readButtonDidPressed), for: .touchUpInside)
        archiveButton.addTarget(self, action: #selector(archiveButtonDidPressed), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonDidPressed), for: .touchUpInside)
        
        editModeStack.addArrangedSubview(readButton)
        editModeStack.addArrangedSubview(archiveButton)
        editModeStack.addArrangedSubview(deleteButton)
        
        addSubview(editModeStack)
        editModeStack.autoPinLeadingToSuperviewMargin(withInset: 16.0)
        editModeStack.autoPinTrailingToSuperviewMargin(withInset: 16.0)
        editModeStack.autoPinTopToSuperviewMargin(withInset: 0.0)
        
        let topLine = UIView()
        topLine.autoSetDimension(.height, toSize: 0.5)
        topLine.backgroundColor = Theme.cellSeparatorColor
        
        addSubview(topLine)
        topLine.autoPinWidthToSuperview()
        topLine.topAnchor.constraint(equalTo: self.topAnchor, constant: -1)
    }
    
    func update(selectedThreads:[ThreadViewModel]) {
        if selectedThreads.isEmpty {
            
            readButton.isEnabled = false
            archiveButton.isEnabled = false
            deleteButton.isEnabled = false
            
            return
        }
        
        var canReadAll = false
        var canArchiveAll = false
//        var canUnarchiveAll = false
        
        for thread in selectedThreads {
            canReadAll = canReadAll || thread.hasUnreadMessages
            canArchiveAll = false
//            canUnarchiveAll = false
        }
        
        // update gui
        readButton.isEnabled = canReadAll
        archiveButton.setTitle( canArchiveAll ? "Archive" : "Unarchive", for: .normal)
        deleteButton.isEnabled = true // cause i'm here - i have one chat at least that can be deleted
    }
    
    @objc func readButtonDidPressed() {
        delegate?.readButtonPressed()
    }
    
    @objc func archiveButtonDidPressed() {
        delegate?.archiveButtonPressed()
    }
    
    @objc func deleteButtonDidPressed() {
        delegate?.deleteButtonPressed()
    }
    
}
