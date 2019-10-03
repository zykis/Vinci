//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation


class VinciChallengeStatisticsRouter: VinciChallengeStatisticsRouterProtocol {
    static func createModule() -> VinciChallengeStatisticsViewController {
        let view = VinciChallengeStatisticsViewController(nibName: nil, bundle: nil)
        let presenter: VinciChallengeStatisticsPresenterProtocol = VinciChallengeStatisticsPresenter()
        var interactor: VinciChallengeStatisticsInteractorProtocol = VinciChallengeStatisticsInteractor()
        let router: VinciChallengeStatisticsRouterProtocol = VinciChallengeStatisticsRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        return view
    }
}
