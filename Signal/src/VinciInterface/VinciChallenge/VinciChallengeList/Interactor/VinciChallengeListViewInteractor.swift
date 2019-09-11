//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

class VinciChallengeListInteractor: VinciChallengeListInteractorProtocol {
    weak var presenter: VinciChallengeListPresenterProtocol?
    
    func fetchChallenges() {
        // TODO: network request to server
        var challenges: [Challenge] = []
        challenges.append(Challenge(title: "#Game1",
                                    reward: 2300, 
                                    startDate: Date(),
                                    expirationDate: Date.init(timeInterval: 7 * 24 * 60 * 60, since: Date()),
                                    description: "Challenge description. Would probably take a few rows of raw text",
                                    iconUrl: "https://cdn.dribbble.com/users/148582/screenshots/7117659/media/ef6b1754faa5edbb4438b275ef985925.png"))
        challenges.append(Challenge(title: "#Game2",
                                    reward: 15,
                                    startDate: Date(),
                                    expirationDate: Date.init(timeInterval: 5 * 60 * 60, since: Date()),
                                    description: "Challenge description. Would probably take a few rows of raw text",
                                    iconUrl: "https://cdn.dribbble.com/users/3281732/screenshots/7118135/media/6984f7984b1052b9bdd5f2e29027ebc9.jpg"))
        
        self.presenter?.challengeFetchSuccess(challenges: challenges)
    }
}
