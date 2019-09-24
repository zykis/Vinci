//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

let kHost: String = "http://3.84.122.119:5000/"
let kEndpointGetChallenges = kHost + "getChallenges"
let kEndpointCreateChallenge = kHost + "createChallenge"
let kEndpointGetMediaMeta = kHost + "getMediaMeta"
let kEndpointGetMediaMetaById = kHost + "getMediaMetaById"
let kEndpointPostComent = kHost + "createCommentForMedia"
let kEndpointLikeMedia = kHost + "likeMedia"
let kEndpointGetMedia = kHost + "getMedia"

class VinciChallengeListInteractor: VinciChallengeListInteractorProtocol {
    weak var presenter: VinciChallengeListPresenterProtocol?
    let dispatchGroup = DispatchGroup()
    
    var startDate: Date?
    
    func fetchChallenges() {
        self.fetchChallenges(limit: 20, offset: 0) { (challenges, error) in
            if let challenges = challenges {
                self.presenter?.challengesFetchSuccess(challenges: challenges)
            } else if let error = error {
                self.presenter?.challengesFetchFail(error: error)
            }
        }
    }
    
    func fetchTopChallenges() {
        self.fetchChallenges(limit: 20, offset: 0) { (challenges, error) in
            if let challenges = challenges {
                self.presenter?.topChallengesFetchSuccess(challenges: challenges)
            } else if let error = error {
                self.presenter?.topChallengesFetchFail(error: error)
            }
        }
    }
    
    private func fetchChallenges(limit: Int, offset: Int, completion:(([Challenge]?, Error?) -> Void)?) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let urlString = kEndpointGetChallenges + "?SIGNALID=\(signalID)&LIMIT=\(limit)&OFFSET=\(offset)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                
                let decoder = JSONDecoder()
                do {
                    let challenges: [Challenge] = try decoder.decode([Challenge].self, from: data)
                    DispatchQueue.main.async {
                        completion?(challenges, nil)
                    }
                } catch let error as NSError {
                    DispatchQueue.main.async {
                        completion?(nil, error)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion?(nil, error)
                    }
                }
            }
            task.resume()
        }
    }
}
