//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


protocol VinciChallengeMediaViewProtocol: class {
}


protocol VinciChallengeMediaPresenterProtocol: class {
    var view: VinciChallengeMediaViewProtocol? {get set}
    var interactor: VinciChallengeMediaInteractorProtocol? {get set}
    var router: VinciChallengeMediaRouterProtocol? {get set}
}


protocol VinciChallengeMediaInteractorProtocol {
    var presenter: VinciChallengeMediaPresenterProtocol? {get set}
}


protocol VinciChallengeMediaRouterProtocol {
    static func createModule() -> VinciChallengeMediaViewController
}
