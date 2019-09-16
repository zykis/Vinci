//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


protocol VinciChallengeAccountViewProtocol: class {
}


protocol VinciChallengeAccountPresenterProtocol: class {
    var view: VinciChallengeAccountViewProtocol? {get set}
    var interactor: VinciChallengeAccountInteractorProtocol? {get set}
    var router: VinciChallengeAccountRouterProtocol? {get set}
}


protocol VinciChallengeAccountInteractorProtocol {
    var presenter: VinciChallengeAccountPresenterProtocol? {get set}
}


protocol VinciChallengeAccountRouterProtocol {
    static func createModule() -> VinciChallengeAccountViewController
}
