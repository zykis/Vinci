//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

extension UIImageView {
    struct MyCache {
        static var cache: NSCache<NSString, UIImage> = NSCache<NSString, UIImage>()
    }
    var cache: NSCache<NSString, UIImage> {
        get {
            MyCache.cache
        }
    }
    
    func downloadAndSetupImage(with url: URL, completion: ((_ ok: Bool) -> Void)?) {
        if let cachedImage = cache.object(forKey: url.absoluteString as NSString) {
            self.image = cachedImage
            return
        }
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
                self.cache.setObject(image, forKey: url.absoluteString as NSString)
                self.image = image
                completion?(true)
            }
        }.resume()
    }
}
