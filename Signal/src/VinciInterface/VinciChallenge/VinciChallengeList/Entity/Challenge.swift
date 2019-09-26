//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

class Challenge: Decodable {
    var id: String?
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date?
    var expirationDate: Date?
    var reward: Double
    var latitude: Double?
    var longitude: Double?
    var iconUrl: String?
    var tags: [String] = []
    var likes: Int = 0
    var favourite: Bool = false
    var medias: [Media] = []
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        
        let start = try container.decode(String.self, forKey: .startDate)
        self.startDate = Date.fromIso8601Representation(isoRepresentation: start)!
        
        let end = try container.decode(String.self, forKey: .endDate)
        self.endDate = Date.fromIso8601Representation(isoRepresentation: end)!
        
        let expiration = try container.decode(String.self, forKey: .expirationDate)
        self.expirationDate = Date.fromIso8601Representation(isoRepresentation: expiration)!
        
        self.reward = try container.decode(Double.self, forKey: .reward)
        
//        let location = try container.decode([Double].self, forKey: .location)
//        self.latitude = location.first
//        self.longitude = location.last
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        
        self.tags = try container.decode([String].self, forKey: .tags)
        self.likes = try container.decode(Int.self, forKey: .likes)
        
        self.favourite = try container.decode(Bool.self, forKey: .favourite)
        
//        self.medias = try container.decode([Media].self, forKey: .medias)
        
        if  let mediaIDs = try container.decodeIfPresent([String].self, forKey: .medias) {
            for mediaID in mediaIDs {
                let media = Media(id: mediaID)
                self.medias.append(media)
            }
        }
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
        case id = "ID"
        case title = "NAME"
        case description = "DESCR"
        case startDate = "BEGIN"
        case endDate = "END"
        case expirationDate = "FINAL"
        case reward = "REWARD"
        case location = "LOC"
        case latitude = "LAT"
        case longitude = "LON"
        case tags = "TAGS"
        case likes = "LIKES"
        case medias = "MEDIA"
        case favourite = "USERFAV"
    }
}
