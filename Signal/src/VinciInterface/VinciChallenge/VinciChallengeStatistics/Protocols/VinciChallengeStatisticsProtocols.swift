//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation


protocol VinciChallengeStatisticsViewProtocol: class {
}

protocol VinciChallengeStatisticsPresenterProtocol: class {
    var view: VinciChallengeStatisticsViewProtocol? {get set}
    var interactor: VinciChallengeStatisticsInteractorProtocol? {get set}
    var router: VinciChallengeStatisticsRouterProtocol? {get set}
    var challenges: [Challenge] {get set}
}

protocol VinciChallengeStatisticsInteractorProtocol {
    var presenter: VinciChallengeStatisticsPresenterProtocol? {get set}
}


protocol VinciChallengeStatisticsRouterProtocol {
    static func createModule() -> VinciChallengeStatisticsViewController
}
