//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeStatisticsPresenter: VinciChallengeStatisticsPresenterProtocol {
    var view: VinciChallengeStatisticsViewProtocol?
    var interactor: VinciChallengeStatisticsInteractorProtocol?
    var router: VinciChallengeStatisticsRouterProtocol?
    
    var challenges: [Challenge] = []
}
