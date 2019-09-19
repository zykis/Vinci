//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class Media: Decodable {
    var id: String?
    var url: String {
        // FIXME: remove endpoint later
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        if let id = self.id {
            return kEndpointGetMedia + "?SIGNALID=\(signalID)&MEDIAID=\(id)"
        }
        return ""
    }
    
    init(id: String) {
        self.id = id
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "MEDIAID"
    }
}
