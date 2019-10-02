//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeGamePresenter: VinciChallengeGamePresenterProtocol {
    var view: VinciChallengeGameViewProtocol?
    var interactor: VinciChallengeGameInteractorProtocol?
    var router: VinciChallengeGameRouterProtocol?
    
    var challenge: Challenge?
    
    func createChallenge(challenge: Challenge, completion: @escaping (String) -> Void) {
        interactor?.createChallenge(challenge: challenge, completion: { (challengeID) in
            completion(challengeID)
        })
    }
    
    func createChallengeFail(error: Error) {
    }
    
    func fetchChallenge(challengeID: String, completion: @escaping (Challenge) -> Void) {
        self.interactor?.fetchChallenge(challengeID: challengeID, completion: { (challenge) in
            self.challenge = challenge
            completion(challenge)
        })
    }
    
    func fetchChallengeFail(error: Error) {
    }
    
    func uploadAvatar(imageData: Data, challengeID: String, latitude: Double?, longitude: Double?, completion: @escaping () -> Void) {
        interactor?.upload(imageData: imageData, for: challengeID, latitude: latitude, longitude: longitude, completion: completion)
    }
    
    func uploadAvatarFail(error: Error) {
        print(error)
    }
    
    func uploadMedia(imageData: Data, challengeID: String, commentsEnabled: Bool, description: String, completion: @escaping () -> Void) {
        if let ch = challenge {
            ChallengeAPIManager.shared.uploadMedia(challengeID: challengeID, name: "whatever", description: description, latitude: ch.latitude, longitude: ch.longitude, mediaData: imageData, completion: completion)
        }
    }
}
