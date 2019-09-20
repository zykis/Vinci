//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit


class VinciChallengeWatchMediaRouter: NSObject, VinciChallengeWatchMediaRouterProtocol {
    @objc static func createModule() -> VinciChallengeWatchMediaViewController {
        let view = VinciChallengeWatchMediaViewController(nibName: nil, bundle: nil)
        let presenter: VinciChallengeWatchMediaPresenterProtocol = VinciChallengeWatchMediaPresenter()
        var interactor: VinciChallengeWatchMediaInteractorProtocol = VinciChallengeWatchMediaInteractor()
        let router: VinciChallengeWatchMediaRouterProtocol = VinciChallengeWatchMediaRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        return view
    }
}
