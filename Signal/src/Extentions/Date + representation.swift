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
    
    func representationSinceNow() -> String {
        let interval: Double = self.timeIntervalSinceNow
        let months: Int = abs(Int(interval / Double(60.0 * 60.0 * 24.0 * 30.0)))
        let weeks: Int = abs(Int(interval / Double(60.0 * 60 * 24 * 7)))
        let days: Int = abs(Int(interval / Double(60 * 60 * 24)))
        let hours: Int = abs(Int(interval / Double(60 * 60)))
        let minutes: Int = abs(Int(interval / 60.0))
        
        if months > 0 {
            return "\(months)months"
        }
        if weeks > 0 {
            return "\(weeks)w"
        }
        if days > 0 {
            return "\(days)d"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "just now"
    }
    
    static func fromIso8601Representation(isoRepresentation: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        var date = formatter.date(from: isoRepresentation)
        if date == nil {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            date = formatter.date(from: isoRepresentation)
        }
        return date
    }
}
