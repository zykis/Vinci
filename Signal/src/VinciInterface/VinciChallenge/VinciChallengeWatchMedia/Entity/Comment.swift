//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


struct CommentPresenter {
    var username: String?
    var text: String?
    var userLike: Bool = false
    var likes: String?
    var avatarUrl: String?
    var posted: String?
}

class Comment: Decodable {
    var id: String?
    var username: String?
    var text: String?
    var userLike: Bool = false
    var likes: Int = 0
    var avatarUrl: String?
    var posted: Date?
    
    func presenter() -> CommentPresenter {
        var presenter = CommentPresenter()
//        if let username = self.username {
//            presenter.username = "@\(username)"
//        }
        presenter.username = "@username"
        presenter.text = self.text
        presenter.userLike = self.userLike
        presenter.likes = "\(self.likes)"
//        presenter.avatarUrl = self.avatarUrl
        presenter.avatarUrl = "https://avatars0.githubusercontent.com/u/5877248?s=460&v=4"
        presenter.posted = posted?.representationSinceNow()
        
        return presenter
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.text = try container.decode(String.self, forKey: .text)
        self.userLike = try container.decode(Bool.self, forKey: .userLike)
        self.likes = try container.decode(Int.self, forKey: .likes)
        
        let dateString = try container.decode(String.self, forKey: .posted)
        self.posted = Date.fromIso8601Representation(isoRepresentation: dateString)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case text = "TEXT"
        case posted = "DATE"
        case userLike = "USERLIKE"
        case likes = "LIKES"
    }
}


class CommentsForMedia: Decodable {
    var count: Int
    var comments: [Comment]
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.count = try container.decode(Int.self, forKey: .count)
        self.comments = try container.decode([Comment].self, forKey: .comments)
    }
    
    enum CodingKeys: String, CodingKey {
        case count = "TOTALCOUNT"
        case comments = "COMMENTS"
    }
}
