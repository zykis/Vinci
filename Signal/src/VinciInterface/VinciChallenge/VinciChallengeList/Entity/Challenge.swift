//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

let kEndpointGetAvatar = kHost + "getAvatar"

class Challenge: Decodable {
    var id: String
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
    var avatarUrl: String? {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        return kEndpointGetAvatar + "?CHID=\(self.id)&SIGNALID=\(signalID)"
    }
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
        
        self.latitude = try container.decode(Double.self, forKey: .latitude)
        self.longitude = try container.decode(Double.self, forKey: .longitude)
        
        self.tags = try container.decode([String].self, forKey: .tags)
        self.likes = try container.decode(Int.self, forKey: .likes)
        
        self.favourite = try container.decode(Bool.self, forKey: .favourite)
        
        if  let mediaIDs = try container.decodeIfPresent([String].self, forKey: .medias) {
            for mediaID in mediaIDs {
                let media = Media(id: mediaID)
                self.medias.append(media)
            }
        }
    }
    
    init(id: String, title: String, description: String?, start: Date, end: Date?, expiration: Date?, reward: Double, latitude: Double?, longitude: Double?, tags: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = start
        self.endDate = end
        self.expirationDate = expiration
        self.reward = reward
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
        self.likes = 0
        self.favourite = false
        self.medias = []
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
