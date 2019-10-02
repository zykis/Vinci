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
}
