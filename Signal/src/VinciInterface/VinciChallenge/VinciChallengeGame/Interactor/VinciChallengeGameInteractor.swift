//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


let kEndpointGetChallenge = kHost + "getChallengeById"
let kEndpointUploadChallengeAvatar = kHost + "uploadAvatar"


class VinciChallengeGameInteractor: VinciChallengeGameInteractorProtocol {
    var presenter: VinciChallengeGamePresenterProtocol?
    
    func createChallenge(challenge: Challenge, completion: @escaping (String) -> Void) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-ddThh:mm:ssZ"
        
        guard
            let description = challenge.description
            else { return }
        
        // FIXME: tags
        let tag = "vinci"
        let begin = challenge.startDate.iso8601Representation()
        let end = challenge.endDate!.iso8601Representation()
        let results = challenge.expirationDate!.iso8601Representation()
        
        var requestString = "SIGNALID=\(signalID)&NAME=\(challenge.title)&DESCR=\(description)&REWARD=\(challenge.reward)&BEGIN=\(begin)&END=\(end)&FINAL=\(results)&TAGS=\(tag)"
        if let lat = challenge.latitude, let lon = challenge.longitude {
            requestString += "&LAT=\(lat)&LON=\(lon)&RADIUS=\(50)"
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
                    let challengeID = jsonObject["CHID"] as! String
                    DispatchQueue.main.async {
                        completion(challengeID)
                    }
                    
                } catch {
                    DispatchQueue.main.async {
                        print(error)
                    }
                }
            }
            task.resume()
        }
    }
    
    func upload(imageData: Data, for challengeID: String, latitude: Double?, longitude: Double?, completion: @escaping () -> Void) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        
        var parameters: [String: String] = [
            "SIGNALID": "\(signalID)",
            "NAME": "whatever",
            "CHID": challengeID,
            "TYPE": "jpg"
        ]
        if let lat = latitude, let lon = longitude {
            parameters["LAT"] = "\(lat)"
            parameters["LON"] = "\(lon)"
        }
        
        if let url = URL(string: kEndpointUploadChallengeAvatar) {
            var urlRequest = URLRequest(url: url)
            let boundary = "Boundary-\(UUID().uuidString)"
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
            urlRequest.httpBody = URLRequest.createFormDataBody(parameters: parameters,
                                                                boundary: boundary,
                                                                dataKey: "media",
                                                                data: imageData,
                                                                mimeType: "multipart/form-data",
                                                                filename: "whatever")
            
            let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                guard
                let r = response as? HTTPURLResponse,
                r.statusCode == 200
                    else { fatalError("error uploading challenge avatar") }
                DispatchQueue.main.async {
                    completion()
                }
            }
            task.resume()
        }
    }
    
    func fetchChallenge(challengeID: String, completion: @escaping (Challenge) -> Void) {
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
                        self.presenter?.challenge = challenge
                        completion(challenge)
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
