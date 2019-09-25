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
    var comments: [Comment] = []
    var _totalCommentsCount: Int = 0
    
    func fetchMedia(mediaID: String) {
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
    
    func postComment(comment: String) {
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
    
    func fetchComments() {
        self._totalCommentsCount = 0
        self.comments = []
        self.interactor?.fetchComments(mediaID: self.mediaID!)
    }
    
    func fetchCommentsSuccess(comments: [Comment], totalCommentsCount: Int) {
        self.comments = comments
        self._totalCommentsCount = totalCommentsCount
        self.view?.fetchCommentsSuccess()
    }
    
    func totalCommentsCount() -> Int {
        return _totalCommentsCount
    }
    
    func commentsCount() -> Int {
        return comments.count
    }
    
    func comment(at: Int) -> Comment? {
        if comments.indices.contains(at) {
            return comments[at]
        }
        return nil
    }
}
