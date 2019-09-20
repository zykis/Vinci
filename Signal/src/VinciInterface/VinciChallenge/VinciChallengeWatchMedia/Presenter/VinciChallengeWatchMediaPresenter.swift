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
    
    func startFetchMedia(with mediaID: String) {
        self.interactor?.fetchMedia(mediaID: mediaID)
    }
    
    func fetchMediaSuccess(media: Media) {
        self.media = media
        self.view?.update(with: media)
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
        print(error)
    }
    
    func likeOrUnlikeMedia(like: Bool) {
        self.interactor?.likeOrUnlikeMedia(mediaID: self.mediaID!, like: like)
    }
    
    func likeOrUnlikeMediaSuccess(like: Bool) {
        self.view?.likeOrUnlikeMediaSuccess()
    }
    
    func likeOrUnlikeMediaFail() {
        self.view?.likeOrUnlikeMediaFail()
    }
}
