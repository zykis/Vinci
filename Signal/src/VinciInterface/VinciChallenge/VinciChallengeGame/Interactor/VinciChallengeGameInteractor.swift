//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


let kEndpointGetChallenge = kHost + "getChallengeById"


class VinciChallengeGameInteractor: VinciChallengeGameInteractorProtocol {
    var presenter: VinciChallengeGamePresenterProtocol?
    
    func createChallenge(challenge: Challenge) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-ddThh:mm:ssZ"
        
        guard
            let description = challenge.description,
            let endDate = challenge.endDate,
            let resultsDate = challenge.expirationDate
            else { return }
        
        // FIXME: tags
        let tag = "vinci"
        let begin = df.string(from: challenge.startDate)
        let end = df.string(from: endDate)
        let results = df.string(from: resultsDate)
        
        
        var requestString = "SIGNALID=\(signalID)&NAME=\(challenge.title)&DESCRIPTION=\(description)&REWARD=\(challenge.reward)&BEGIN=\(begin)&END=\(end)&FINAL=\(results)&TAGS=\(tag)"
        if let lat = challenge.latitude, let lon = challenge.longitude {
           requestString += "&LAT=\(lat)&LON=\(lon)"
        }
        
        if let url = URL(string: kEndpointCreateChallenge) {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = requestString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard let data = data
                    else { return }
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
                    let challengeID = jsonObject["ID"] as! String
                    DispatchQueue.main.async {
                        self.presenter?.createChallengeSuccess(challengeID: challengeID)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self.presenter?.createChallengeFail(error: error)
                    }
                }
            }
            task.resume()
        }
    }
    
    func fetchChallenge(challengeID: String) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let urlString = kEndpointGetChallenge + "?SIGNALID=\(signalID)&CHID=\(challengeID)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data
                    else { return }
                let decoder = JSONDecoder()
                do {
                    let challenge = try decoder.decode(Challenge.self, from: data)
                    DispatchQueue.main.async {
                        self.presenter?.fetchChallengeSuccess(challenge: challenge)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        self.presenter?.fetchChallengeFail(error: error)
                    }
                }
            }
            task.resume()
        }
    }
}
