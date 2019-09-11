//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


protocol VinciChallengeListViewProtocol: class {
    func updateChallengeList()
}


protocol VinciChallengeListPresenterProtocol: class {
    var view: VinciChallengeListViewProtocol? {get set}
    var interactor: VinciChallengeListInteractorProtocol? {get set}
    var router: VinciChallengeListRouterProtocol? {get set}
    
    func startFetchingChallenges()
    func challengeFetchSuccess(challenges: [Challenge])
    func challengeFetchFail(error: Error)
    
    func challenge(at indexPath: IndexPath) -> Challenge
    func challengeCount() -> Int
}


protocol VinciChallengeListInteractorProtocol {
    var presenter: VinciChallengeListPresenterProtocol? {get set}
    
    func fetchChallenges()
}


protocol VinciChallengeListRouterProtocol {
    static func createModule() -> VinciChallengeListViewController
}
