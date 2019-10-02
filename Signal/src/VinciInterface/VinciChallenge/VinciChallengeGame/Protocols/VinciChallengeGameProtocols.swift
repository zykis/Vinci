//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation


protocol VinciChallengeGameViewProtocol: class {
}


protocol VinciChallengeGamePresenterProtocol: class {
    var view: VinciChallengeGameViewProtocol? {get set}
    var interactor: VinciChallengeGameInteractorProtocol? {get set}
    var router: VinciChallengeGameRouterProtocol? {get set}
    
    var challenge: Challenge? {get set}
    
    func createChallenge(challenge: Challenge, completion: @escaping (String) -> Void)
    func uploadAvatar(imageData: Data, challengeID: String, latitude: Double?, longitude: Double?, completion: @escaping () -> Void)
    func uploadMedia(imageData: Data, challengeID: String, commentsEnabled: Bool, description: String, completion: @escaping () -> Void)
    
    func fetchChallenge(challengeID: String, completion: @escaping (Challenge) -> Void)
    func fetchChallengeFail(error: Error)
}


protocol VinciChallengeGameInteractorProtocol {
    var presenter: VinciChallengeGamePresenterProtocol? {get set}
    
    func upload(imageData: Data, for challengeID: String, latitude: Double?, longitude: Double?, completion: @escaping () -> Void)
    func createChallenge(challenge: Challenge, completion: @escaping (String) -> Void)
    func fetchChallenge(challengeID: String, completion: @escaping (Challenge) -> Void)
}


protocol VinciChallengeGameRouterProtocol {
    static func createModule(gameState: GameState) -> VinciChallengeGameViewController
}
