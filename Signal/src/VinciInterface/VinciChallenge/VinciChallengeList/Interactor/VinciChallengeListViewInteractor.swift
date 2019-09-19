//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

let kHost: String = "http://3.84.122.119:5000/"
let kEndpointGetChallenges = kHost + "getChallenges"
let kEndpointCreateChallenge = kHost + "createChallenge"
let kEndpointGetMediaMeta = kHost + "getMediaMeta"
let kEndpointGetMedia = kHost + "getMedia"

class VinciChallengeListInteractor: VinciChallengeListInteractorProtocol {
    weak var presenter: VinciChallengeListPresenterProtocol?
    let dispatchGroup = DispatchGroup()
    
    var startDate: Date?
    
    func fetchChallenges() {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let urlString = kEndpointGetChallenges + "?SIGNALID=\(signalID)&LIMIT=\(100)&OFFSET=\(0)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                
                let decoder = JSONDecoder()
                do {
                    let challenges: [Challenge] = try decoder.decode([Challenge].self, from: data)
                    DispatchQueue.main.async {
                        self.presenter?.challengeFetchSuccess(challenges: challenges)
                    }
                } catch let error as NSError {
                    DispatchQueue.main.async {
                        self.presenter?.challengeFetchFail(error: error)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.presenter?.challengeFetchFail(error: NSError(domain: "com.vinci", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get list of challenges"]))
                    }
                }
            }
            task.resume()
        }
    }
    
    func fetchChallengesWithMedia() {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let urlString = kEndpointGetChallenges + "?SIGNALID=\(signalID)&LIMIT=\(100)&OFFSET=\(0)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                
                let decoder = JSONDecoder()
                do {
                    let challenges: [Challenge] = try decoder.decode([Challenge].self, from: data)
                    
                    self.startDate = Date()
                    
                    for challenge in challenges {
                        self.dispatchGroup.enter()
                        self.fetchChallengeMedia(challenge: challenge, dispatchGroup: self.dispatchGroup, completionHandler: { (medias) in
                            challenge.medias = medias
                            self.dispatchGroup.leave()
                        })
                    }
                    
                    self.dispatchGroup.notify(queue: .main, execute: {
                        print("MEDIA METADATA REQUEST TIME: \(Date().timeIntervalSince(self.startDate!))")
                        self.presenter?.challengeFetchSuccess(challenges: challenges)
                    })
                } catch {
                    DispatchQueue.main.async {
                        self.presenter?.challengeFetchFail(error: NSError(domain: "com.vinci", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get list of challenges"]))
                    }
                }
            }
            task.resume()
        }
    }
    
    private func fetchChallengeMedia(challenge: Challenge, dispatchGroup: DispatchGroup, completionHandler: @escaping ([Media]) -> Void) {
        let start = Date()
        
        let signalID = "4310"
        let urlString = kEndpointGetMediaMeta + "?LIMIT=20&OFFSET=0&SIGNALID=\(signalID)&CHID=\(challenge.id!)"
//        let urlString = "https://www.google.com/search?client=safari&rls=en&q=\(challenge.id!)&ie=UTF-8&oe=UTF-8"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                print("SINGLE MEDIA METADATA REQUEST TIME: \(Date().timeIntervalSince(start))")
                
                let decoder = JSONDecoder()
                
                do {
                    let medias: [Media] = try decoder.decode([Media].self, from: data)
                    completionHandler(medias)
                } catch {
                    dispatchGroup.leave()
                }
            }
            task.resume()
        }
    }
}
