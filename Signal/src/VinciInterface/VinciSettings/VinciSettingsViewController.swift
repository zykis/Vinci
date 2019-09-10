//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class VinciSettingsViewController: VinciViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.orange
        
        // set navigation bar not to be transparent
        navigationController?.navigationBar.backgroundColor = Theme.backgroundColor
        navigationController?.navigationBar.isTranslucent = false
        
        title = "Settings"
        
        updateBarButtonItems()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func updateBarButtonItems() {
        let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissViewController))
        navigationItem.leftBarButtonItem = closeButton
    }
    
    @objc func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
}
