//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit


class VinciChallengeAccountRouter: NSObject, VinciChallengeAccountRouterProtocol {
    @objc static func createModule() -> VinciChallengeAccountViewController {
        let view = VinciChallengeAccountViewController(nibName: nil, bundle: nil)
        let presenter: VinciChallengeAccountPresenterProtocol = VinciChallengeAccountPresenter()
        var interactor: VinciChallengeAccountInteractorProtocol = VinciChallengeAccountInteractor()
        let router: VinciChallengeAccountRouterProtocol = VinciChallengeAccountRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        return view
    }
}
