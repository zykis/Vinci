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
}
