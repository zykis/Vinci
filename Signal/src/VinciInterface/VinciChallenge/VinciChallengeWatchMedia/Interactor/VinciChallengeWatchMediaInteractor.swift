//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeWatchMediaInteractor: VinciChallengeWatchMediaInteractorProtocol {
    var presenter: VinciChallengeWatchMediaPresenterProtocol?
    
    func fetchMedia(mediaID: String) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
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
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        guard
            let mediaID = self.presenter?.mediaID,
            let url = URL(string: kEndpointPostComent)
        else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)&TEXT=\(comment)".data(using: .utf8)
        let requestString = "SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)&TEXT=\(comment)"
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode < 300 {
                    DispatchQueue.main.async {
                        self.presenter?.postingCommentSuccess()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.presenter?.postingCommentFail(error: NSError(domain: "com.vinci", code: httpResponse.statusCode, userInfo: nil))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.presenter?.postingCommentFail(error: NSError(domain: "com.vinci", code: 1, userInfo: nil))
                }
            }
        }
        task.resume()
    }
    
    static func likeOrUnlikeMedia(mediaID: String, completion: ((Bool) -> Void)?) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        guard
            let url = URL(string: kEndpointLikeMedia + "?SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)")
            else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID)".data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 300 {
                DispatchQueue.main.async {
                    completion?(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
        task.resume()
    }
    
    func likeOrUnlikeMedia(mediaID: String) {
        VinciChallengeWatchMediaInteractor.likeOrUnlikeMedia(mediaID: mediaID) { (completed) in
            if completed {
                self.presenter?.likeOrUnlikeMediaSuccess()
            } else {
                self.presenter?.likeOrUnlikeMediaFail(error: NSError(domain: "com.vinci", code: 1, userInfo: nil))
            }
        }
    }
}
