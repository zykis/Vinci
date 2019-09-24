//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


protocol VinciChallengeListViewProtocol: class {
    func updateChallengeList()
    func updateTopChallengeList()
}


protocol VinciChallengeListPresenterProtocol: class {
    var view: VinciChallengeListViewProtocol? {get set}
    var interactor: VinciChallengeListInteractorProtocol? {get set}
    var router: VinciChallengeListRouterProtocol? {get set}
    
    func startFetchingChallenges()
    func startFetchingTopChallenges()
    
    func challengesFetchSuccess(challenges: [Challenge])
    func challengesFetchFail(error: Error)
    func topChallengesFetchSuccess(challenges: [Challenge])
    func topChallengesFetchFail(error: Error)
    
    func mediasFetchSuccess(medias: [Media])
    func mediasFetchFail(error: Error)
    
    func challenge(at indexPath: IndexPath) -> Challenge?
    func challengeCount() -> Int
    func getTopChallenges() -> [Challenge]
}


protocol VinciChallengeListInteractorProtocol {
    var presenter: VinciChallengeListPresenterProtocol? {get set}
    
    func fetchChallenges()
    func fetchTopChallenges()
}


protocol VinciChallengeListRouterProtocol {
    static func createModule() -> VinciChallengeListViewController
}
