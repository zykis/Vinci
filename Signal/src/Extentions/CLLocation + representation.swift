//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import CoreLocation


extension CLLocation {
    func representation(callback: @escaping (String) -> Void) {
        let ceo: CLGeocoder = CLGeocoder()
        ceo.reverseGeocodeLocation(self, completionHandler:
            {(placemarks, error) in
                if let pm = placemarks?.first {
                    var addressString : String = ""
                    if let country = pm.country {
                        addressString = addressString + country + ", "
                    }
                    if let locality = pm.locality {
                        addressString = addressString + locality
                    }
                    callback(addressString)
                }
        })
    }
}
