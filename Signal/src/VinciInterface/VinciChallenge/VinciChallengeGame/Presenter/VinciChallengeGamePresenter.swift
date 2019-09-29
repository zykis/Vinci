//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeGamePresenter: VinciChallengeGamePresenterProtocol {
    var view: VinciChallengeGameViewProtocol?
    var interactor: VinciChallengeGameInteractorProtocol?
    var router: VinciChallengeGameRouterProtocol?
    
    var challenge: Challenge?
    
    func createChallenge(challenge: Challenge) {
        interactor?.createChallenge(challenge: challenge)
    }
    
    func createChallengeSuccess(challengeID: String) {
        view?.createChallengeSuccess()
    }
    
    func createChallengeFail(error: Error) {
    }
    
    func fetchChallenge(challengeID: String) {
        self.interactor?.fetchChallenge(challengeID: challengeID)
    }
    
    func fetchChallengeSuccess(challenge: Challenge) {
        self.challenge = challenge
        self.view?.fetchChallengeSuccess(challenge: challenge)
    }
    
    func fetchChallengeFail(error: Error) {
    }
}
