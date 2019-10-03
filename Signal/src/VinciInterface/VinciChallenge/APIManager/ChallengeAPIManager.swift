//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

let kEndpointUploadMedia = kHost + "uploadMedia"
let kEndpointFavourChallenge = kHost + "favChallenge"

class ChallengeAPIManager {
    static let shared = ChallengeAPIManager()
    
    private init() {
    }
    
    func uploadMedia(challengeID: String,
                     name: String?,
                     description: String?,
                     latitude: Double?,
                     longitude: Double?,
                     mediaData: Data,
                     completion: @escaping () -> Void) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        
        var parameters: [String: String] = [
            "SIGNALID": "\(signalID)",
            "CHID": challengeID,
            "NAME": name ?? "whatever",
            "DESCR": description ?? "whatever description",
            "TYPE": "jpg"
        ]
        if let lat = latitude, let lon = longitude {
            parameters["LAT"] = "\(lat)"
            parameters["LON"] = "\(lon)"
        }
        
        if let url = URL(string: kEndpointUploadMedia) {
            var urlRequest = URLRequest(url: url)
            let boundary = "Boundary-\(UUID().uuidString)"
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("\(mediaData.count)", forHTTPHeaderField: "Content-Length")
            urlRequest.httpBody = URLRequest.createFormDataBody(parameters: parameters,
                                                                boundary: boundary,
                                                                dataKey: "media",
                                                                data: mediaData,
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
    
    func favourChallenge(challengeID: String, completion: @escaping (Bool) -> Void) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        guard
            let url = URL(string: kEndpointFavourChallenge)
            else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "SIGNALID=\(signalID)&CHID=\(challengeID)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data
                else { return }
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
                let favourite = jsonObj["USERFAV"] as! Bool
                DispatchQueue.main.async {
                    completion(favourite)
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    func fetchChallenges(participant: Bool?, finished: Bool?, owner: Bool?, limit: Int, offset: Int, completion:(([Challenge]?, Error?) -> Void)?) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        var parameters: [String: String] = [
            "SIGNALID": "\(signalID)",
            "LIMIT": "\(limit)",
            "OFFSET": "\(offset)"
        ]
        if let participant = participant, participant == true {
            parameters["PARTICIPANTID"] = "\(signalID)"
        }
        if let finished = finished {
            parameters["FINISHED"] = finished ? "true" : "false"
        }
        if let owner = owner, owner == true {
            parameters["OWNERID"] = "\(signalID)"
        }
        var urlString = kEndpointGetChallenges
        if parameters.isEmpty == false {
            urlString += "?"
            for p in parameters {
                urlString += p.key + "=" + p.value + "&"
            }
            urlString.removeLast()
        }
        
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
