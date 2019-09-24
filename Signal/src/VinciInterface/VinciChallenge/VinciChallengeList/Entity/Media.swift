//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class Media: Decodable {
    var id: String?
    var url: String {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        if let id = self.id {
            return kEndpointGetMedia + "?SIGNALID=\(signalID)&MEDIAMETAID=\(id)"
        }
        return ""
    }
    var username: String?
    var description: String?
    var likes: Int = 0
    var comments: Int = 0
    var reposts: Int = 0
    var userLike: Bool = false
    var userFavourite: Bool = false
    
    init(id: String) {
        self.id = id
    }
    
    init(media: Media) {
        self.id = media.id
        self.username = media.username
        self.description = media.description
        self.likes = media.likes
        self.comments = media.comments
        self.reposts = media.reposts
        self.userLike = media.userLike
        self.userFavourite = media.userFavourite
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.likes = try container.decodeIfPresent(Int.self, forKey: .likes) ?? 0
        self.userLike = try container.decodeIfPresent(Bool.self, forKey: .userLike) ?? false
        self.comments = try container.decodeIfPresent(Int.self, forKey: .comments) ?? 0
        self.reposts = try container.decodeIfPresent(Int.self, forKey: .reposts) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case description = "DESCR"
        case likes = "LIKES"
        case userLike = "USERLIKE"
        case comments = "COMMENTS"
        case reposts = "REPOSTS"
    }
}
