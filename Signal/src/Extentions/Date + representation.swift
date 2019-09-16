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
    
    static func fromIso8601Representation(isoRepresentation: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
//        formatter.calendar = Calendar(identifier: .iso8601)
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
//        formatter.locale = Locale(identifier: "ru")
        return formatter.date(from: isoRepresentation)
    }
}
