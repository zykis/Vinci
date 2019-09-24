//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


protocol VinciChallengeWatchMediaViewProtocol: class {
    func update(media: Media)
    func hideOverlay()
    func postingCommentSuccess()
    func postingCommentFail(error: Error)
    func likeOrUnlikeMediaSuccess()
    func likeOrUnlikeMediaFail(error: Error)
}


protocol VinciChallengeWatchMediaPresenterProtocol: class {
    var view: VinciChallengeWatchMediaViewProtocol? {get set}
    var interactor: VinciChallengeWatchMediaInteractorProtocol? {get set}
    var router: VinciChallengeWatchMediaRouterProtocol? {get set}
    
    var mediaID: String? {get set}
    var media: Media? {get set}
    
    func startFetchMedia(mediaID: String)
    func startPostingComment(comment: String)
    func likeOrUnlikeMedia()
    
    func fetchMediaSuccess(media: Media)
    func fetchMediaFail(error: Error)
    func postingCommentSuccess()
    func postingCommentFail(error: Error)
    func likeOrUnlikeMediaSuccess()
    func likeOrUnlikeMediaFail(error: Error)
}


protocol VinciChallengeWatchMediaInteractorProtocol {
    var presenter: VinciChallengeWatchMediaPresenterProtocol? {get set}
    
    func fetchMedia(mediaID: String)
    func postComment(comment: String)
    func likeOrUnlikeMedia(mediaID: String)
}


protocol VinciChallengeWatchMediaRouterProtocol {
    static func createModule() -> VinciChallengeWatchMediaViewController
}
