//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeWatchMediaInteractor: VinciChallengeWatchMediaInteractorProtocol {
    var presenter: VinciChallengeWatchMediaPresenterProtocol?
    
    func fetchMedia(mediaID: String) {
        let signalID = 4310
        let urlString = kEndpointGetMediaMetaById + "?SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                let decoder = JSONDecoder()
                
                do {
                    let media: Media = try decoder.decode(Media.self, from: data)
                    DispatchQueue.main.async {
                        self.presenter?.fetchMediaSuccess(media: media)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.presenter?.fetchMediaFail(error: error)
                    }
                }
            }
            task.resume()
        }
    }
    
    func postComment(comment: String) {
        let signalID = 4310
        guard
            let mediaID = self.presenter?.mediaID,
            let url = URL(string: kEndpointPostComent + "?SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)")
        else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.presenter?.postingCommentFail(error: error)
                }
            } else {
                DispatchQueue.main.async {
                    self.presenter?.postingCommentSuccess()
                }
            }
        }
        task.resume()
    }
    
    func likeOrUnlikeMedia(mediaID: String, like: Bool) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        guard
            let mediaID = self.presenter?.mediaID,
            let url = URL(string: kEndpointLikeMedia + "?SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)")
            else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)".data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard
                let data = data
                else { return }
            if let error = error {
                print(error)
            } else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable:Any]
                    let likes = (json["LIKES"] as? NSNumber)?.intValue
                    DispatchQueue.main.async {
                        self.presenter?.media?.likes = likes!
                        self.presenter?.likeOrUnlikeMediaSuccess(like: true)
                    }
                }
                catch {
                    print(error)
                }
            }
        }
        task.resume()
    }
}
