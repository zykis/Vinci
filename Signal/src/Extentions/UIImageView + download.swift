//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

extension UIImageView {
    func downloadAndSetupImage(with url: URL, completion: ((_ ok: Bool) -> Void)?) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else {
                    completion?(false)
                    return
            }
            DispatchQueue.main.async() {
                self.image = image
                completion?(true)
            }
            }.resume()
    }
}
