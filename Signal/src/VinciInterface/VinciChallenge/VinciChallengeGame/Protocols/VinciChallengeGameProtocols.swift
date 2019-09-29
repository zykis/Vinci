//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation


protocol VinciChallengeGameViewProtocol: class {
    func createChallengeSuccess()
    func fetchChallengeSuccess(challenge: Challenge)
}


protocol VinciChallengeGamePresenterProtocol: class {
    var view: VinciChallengeGameViewProtocol? {get set}
    var interactor: VinciChallengeGameInteractorProtocol? {get set}
    var router: VinciChallengeGameRouterProtocol? {get set}
    
    var challenge: Challenge? {get set}
    
    func createChallenge(challenge: Challenge)
    func createChallengeSuccess(challengeID: String)
    func createChallengeFail(error: Error)
    
    func fetchChallenge(challengeID: String)
    func fetchChallengeSuccess(challenge: Challenge)
    func fetchChallengeFail(error: Error)
}


protocol VinciChallengeGameInteractorProtocol {
    var presenter: VinciChallengeGamePresenterProtocol? {get set}
    
    func createChallenge(challenge: Challenge)
    func fetchChallenge(challengeID: String)
}


protocol VinciChallengeGameRouterProtocol {
    static func createModule(gameState: GameState) -> VinciChallengeGameViewController
}
