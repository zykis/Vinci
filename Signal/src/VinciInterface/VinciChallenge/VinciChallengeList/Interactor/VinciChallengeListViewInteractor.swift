//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

let kHost: String = "http://3.84.122.119:5000/"
let kEndpointGetChallenges = kHost + "getChallenges"
let kEndpointCreateChallenge = kHost + "createChallenge"

class VinciChallengeListInteractor: VinciChallengeListInteractorProtocol {
    weak var presenter: VinciChallengeListPresenterProtocol?
    
    func fetchChallenges(limit: Int? = 0, offset: Int? = nil, signalID: String? = nil) {
        var paramString = ""
        var firstParamReady: Bool = false
        
        if let limit = limit {
            if firstParamReady == false {
                paramString.append("?")
                firstParamReady = true
            }
            paramString.append("LIMIT=\(limit)")
        }
        if let offset = offset {
            if firstParamReady == false {
                paramString.append("?")
                firstParamReady = true
            } else {
                paramString.append("&")
            }
            paramString.append("OFFSET=\(offset)")
        }
        if let signalID = signalID {
            if firstParamReady == false {
                paramString.append("?")
                firstParamReady = true
            } else {
                paramString.append("&")
            }
            paramString.append("SIGNALID=\(signalID)")
        }
        
        let urlString = kEndpointGetChallenges + paramString
        
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
    
//    func createChallenge(challenge: Challenge) {
//        let header = ["Content-Type": "application/x-www-form-urlencoded"]
//        let url = URL(string: "\(kHost)/createChallenge")
//        var postDataString =
//            """
//                SIGNALID=\(TSAccountManager.sharedInstance().getOrGenerateRegistrationId())&"
//                NAME=\(challenge.title)&
//                DESCR=\(challenge.description ?? "")&
//                REWARD=\(challenge.reward)&
//                BEGIN=\(challenge.startDate.representation())&
//                END=\(challenge.endDate?.representation() ?? "")&
//                FINAL=\(challenge.expirationDate?.representation() ?? "")&
//                LOC=\(challenge.latitude ?? 0.0)&
//                LOC=\(challenge.longitude ?? 0.0)
//            """
//        for tag in challenge.tags {
//            postDataString.append("&TAG=\(tag)")
//        }
//        let postData = Data(postDataString.data(using: .utf8)!)
//        var request: URLRequest = URLRequest(url: url!)
//        request.allHTTPHeaderFields = header
//        request.httpMethod = "POST"
//        request.httpBody = postData
//
//        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//            guard let data = data else { return }
//
//            let decoder = JSONDecoder()
//            do {
//                let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
//                let challengeID: String = jsonObject["CHID"]
//
//                self.presenter?.challengeCreationSuccess(challengeID: <#T##Int#>)
//            } catch let decodeError as NSError {
//                completion(nil, decodeError)
//            } catch {
//                completion(nil, NSError(domain: "com.zykis.Github", code: 2, userInfo: [NSLocalizedDescriptionKey: "Uknowned error"]))
//            }
//        }
//    }
}
