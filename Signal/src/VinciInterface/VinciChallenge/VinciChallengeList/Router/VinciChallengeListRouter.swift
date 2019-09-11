//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit

@objc class VinciChallengeListRouter: NSObject, VinciChallengeListRouterProtocol {
    @objc static func createModule() -> VinciChallengeListViewController {
        let view = VinciChallengeListViewController(nibName: nil, bundle: nil)
        let presenter: VinciChallengeListPresenterProtocol = VinciChallengeListPresenter()
        var interactor: VinciChallengeListInteractorProtocol = VinciChallengeListInteractor()
        let router: VinciChallengeListRouterProtocol = VinciChallengeListRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        return view
    }
}
