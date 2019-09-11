//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

extension Date {
    func representation() -> String {
        let dateFormatter = DateFormatter()
        let dateFormat = "dd.MM.yyyy"
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self).capitalized
    }
}
