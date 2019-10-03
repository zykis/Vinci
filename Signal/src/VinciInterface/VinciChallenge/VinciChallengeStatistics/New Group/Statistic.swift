//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class Statistic: Decodable {
    var totalLikes: Int = 0
    var totalReward: Double = 0.0
    var wins: Int = 0
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalLikes = try container.decode(Int.self, forKey: .likes)
        totalReward = try container.decode(Double.self, forKey: .reward)
        wins = try container.decodeIfPresent(Int.self, forKey: .wins) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case likes = "LIKES"
        case reward = "REWARD"
        case wins = "WINS"
        case players = "USERS"
    }
}
