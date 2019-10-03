//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VinciViewController: OWSViewController {
    
    @objc var isViewVisible:Bool = false
    @objc var hasEverAppeared:Bool = false
    
    @objc var rootNavigationDelegate:VinciTabBarControllerDelegate?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isViewVisible = true
        self.hasEverAppeared = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.isViewVisible = false
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}

extension SignalAccount {
    @objc func stringForCollation() -> String {
        if let contactsManager = Environment.shared.contactsManager {
            return contactsManager.comparableName(for: self)
        }
        
        return "#"
    }
}

@objc
public extension UIViewController {
    func presentAlert(_ alert: UIAlertController) {
        self.presentAlert(alert, animated: true)
    }
    
    func presentAlert(_ alert: UIAlertController, animated: Bool) {
        self.present(alert,
                     animated: animated,
                     completion: {
                        alert.applyAccessibilityIdentifiers()
        })
    }
    
    func presentAlert(_ alert: UIAlertController, completion: @escaping (() -> Void)) {
        self.present(alert,
                     animated: true,
                     completion: {
                        alert.applyAccessibilityIdentifiers()
                        
                        completion()
        })
    }
}

extension UIAlertController {
    @objc
    public func applyAccessibilityIdentifiers() {
        for action in actions {
            guard let view = action.value(forKey: "__representer") as? UIView else {
                owsFailDebug("Missing representer.")
                continue
            }
            view.accessibilityIdentifier = action.accessibilityIdentifier
        }
    }
}

// MARK: -

extension UIAlertAction {
    private struct AssociatedKeys {
        static var AccessibilityIdentifier = "ows_accessibilityIdentifier"
    }
    
    @objc
    public var accessibilityIdentifier: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.AccessibilityIdentifier) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.AccessibilityIdentifier, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}


public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    class func once(token: String, block:()->Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

extension UILocalizedIndexedCollation {
    // func for partition array in sections
    func partitionObjects(array:[AnyObject], collationStringSelector:Selector) -> [AnyObject] {
        var unsortedSections = [[AnyObject]]()
        // 1. Create a array to hold the data for each section
        for _ in self.sectionTitles {
            unsortedSections.append([]) //appending an empty array
        }
        // 2. put each objects into a section
        for item in array {
            let index:Int = self.section(for: item, collationStringSelector:collationStringSelector)
            unsortedSections[index].append(item)
        }
        // 3. sort the array of each sections
        var sections = [AnyObject]()
        for index in 0 ..< unsortedSections.count {
            sections.append(self.sortedArray(from: unsortedSections[index], collationStringSelector: collationStringSelector) as AnyObject)
        }
        return sections
    }
}
