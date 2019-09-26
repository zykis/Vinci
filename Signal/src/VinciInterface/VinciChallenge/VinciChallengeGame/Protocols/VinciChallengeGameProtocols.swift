//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation


protocol VinciChallengeGameViewProtocol: class {
}


protocol VinciChallengeGamePresenterProtocol: class {
    var view: VinciChallengeGameViewProtocol? {get set}
    var interactor: VinciChallengeGameInteractorProtocol? {get set}
    var router: VinciChallengeGameRouterProtocol? {get set}
}


protocol VinciChallengeGameInteractorProtocol {
    var presenter: VinciChallengeGamePresenterProtocol? {get set}
}


protocol VinciChallengeGameRouterProtocol {
    static func createModule() -> VinciChallengeGameViewController
}
