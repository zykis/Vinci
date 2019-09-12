//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

class Challenge: Decodable {
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date?
    var expirationDate: Date?
    var reward: Double
    var latitude: Double?
    var longitude: Double?
    var iconUrl: String?
    var likes: Int = 0
    var favourite: Bool = false
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.startDate = try container.decode(Date.self, forKey: .startDate)
        self.endDate = try container.decode(Date.self, forKey: .endDate)
        self.expirationDate = try container.decode(Date.self, forKey: .expirationDate)
        self.reward = try container.decode(Double.self, forKey: .reward)
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
    }
    
    init(title: String, reward: Double, startDate: Date = Date()) {
        self.title = title
        self.reward = reward
        self.startDate = startDate
        self.expirationDate = Date(timeInterval: 7 * 24 * 60 * 60, since: startDate)
    }
    
    convenience init(title: String, reward: Double, startDate: Date, expirationDate: Date, description: String, iconUrl: String) {
        self.init(title: title, reward: reward, startDate: startDate)
        self.expirationDate = expirationDate
        self.description = description
        self.iconUrl = iconUrl
    }
    
    enum CodingKeys: String, CodingKey {
        case title = "NAME"
        case description = "DESCR"
        case startDate = "START"
        case endDate = "END"
        case expirationDate = "FINAL"
        case reward = "REWARD"
        case latitude = "LAT"
        case longitude = "LON"
    }
}
