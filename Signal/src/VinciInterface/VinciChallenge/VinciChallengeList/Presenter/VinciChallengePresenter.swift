//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

class VinciChallengeListPresenter: VinciChallengeListPresenterProtocol {
    weak var view: VinciChallengeListViewProtocol?
    var interactor: VinciChallengeListInteractorProtocol?
    var router: VinciChallengeListRouterProtocol?
    
    var challenges: [Challenge] = []
    var topChallenges: [Challenge] = []
    
    func startFetchingChallenges() {
        self.interactor?.fetchChallenges()
    }
    
    func startFetchingTopChallenges() {
        self.interactor?.fetchTopChallenges()
    }
    
    func challengesFetchSuccess(challenges: [Challenge]) {
        self.challenges = challenges
        self.view?.updateChallengeList()
    }
    
    func topChallengesFetchSuccess(challenges: [Challenge]) {
        self.topChallenges = challenges
        self.view?.updateTopChallengeList()
    }
    
    func challengesFetchFail(error: Error) {
        // TODO: handle error
    }
    
    func topChallengesFetchFail(error: Error) {
        // TODO: handle error
    }
    
    func mediasFetchSuccess(medias: [Media]) {
        self.view?.updateChallengeList()
    }
    
    func mediasFetchFail(error: Error) {
        // TODO: handle error
    }
    
    func challenge(at indexPath: IndexPath) -> Challenge? {
        if self.challenges.indices.contains(indexPath.row) {
            return self.challenges[indexPath.row]
        }
        return nil
    }
    
    func challengeCount() -> Int {
        return self.challenges.count
    }
    
    func getTopChallenges() -> [Challenge] {
        return self.topChallenges
    }
}
