//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeWatchMediaPresenter: VinciChallengeWatchMediaPresenterProtocol {
    var view: VinciChallengeWatchMediaViewProtocol?
    var interactor: VinciChallengeWatchMediaInteractorProtocol?
    var router: VinciChallengeWatchMediaRouterProtocol?
    
    var media: Media?
    var mediaID: String?
    
    func startFetchMedia(mediaID: String) {
        self.interactor?.fetchMedia(mediaID: mediaID)
    }
    
    func fetchMediaSuccess(media: Media) {
        self.media = media
        self.view?.update(media: media)
        self.view?.hideOverlay()
    }
    
    func fetchMediaFail(error: Error) {
        print(error)
    }
    
    func startPostingComment(comment: String) {
        self.interactor?.postComment(comment: comment)
    }
    
    func postingCommentSuccess() {
        self.view?.postingCommentSuccess()
    }
    
    func postingCommentFail(error: Error) {
        self.view?.postingCommentFail(error: error)
    }
    
    func likeOrUnlikeMedia() {
        self.interactor?.likeOrUnlikeMedia(mediaID: self.mediaID!)
    }
    
    func likeOrUnlikeMediaSuccess() {
        self.view?.likeOrUnlikeMediaSuccess()
    }
    
    func likeOrUnlikeMediaFail(error: Error) {
        self.view?.likeOrUnlikeMediaFail(error: error)
    }
}
