//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

class VinciChallengeListPresenter: VinciChallengeListPresenterProtocol {
    weak var view: VinciChallengeListViewProtocol?
    var interactor: VinciChallengeListInteractorProtocol?
    var router: VinciChallengeListRouterProtocol?
    
    var challenges: [Challenge] = []
    
    func startFetchingChallenges(limit: Int?, offset: Int?, signalID: String?) {
        self.interactor?.fetchChallengesWithMedia()
    }
    
    func challengeFetchSuccess(challenges: [Challenge]) {
        self.challenges = challenges
        self.view?.updateChallengeList()
    }
    
    func challengeFetchFail(error: Error) {
        // TODO: handle error
    }
    
    func mediasFetchSuccess(medias: [Media]) {
        // FIXME: insert challenge may be?
        // Multiple times update whole tableView isn't good
        self.view?.updateChallengeList()
    }
    
    func mediasFetchFail(error: Error) {
        // TODO: handle error
    }
    
    func challenge(at indexPath: IndexPath) -> Challenge {
        return self.challenges[indexPath.row]
    }
    
    func challengeCount() -> Int {
        return self.challenges.count
    }
}
