//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

class Challenge {
    var title: String
    var description: String?
    var startDate: Date
    var expirationDate: Date?
    var reward: Int
    var iconUrl: String?
    var likes: Int = 0
    var favourite: Bool = false
    
    init(title: String, reward: Int, startDate: Date = Date()) {
        self.title = title
        self.reward = reward
        self.startDate = startDate
        self.expirationDate = Date(timeInterval: 7 * 24 * 60 * 60, since: startDate)
    }
    
    convenience init(title: String, reward: Int, startDate: Date, expirationDate: Date, description: String, iconUrl: String) {
        self.init(title: title, reward: reward, startDate: startDate)
        self.expirationDate = expirationDate
        self.description = description
        self.iconUrl = iconUrl
    }
}
