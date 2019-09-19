//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit


class VinciChallengeMediaRouter: NSObject, VinciChallengeMediaRouterProtocol {
    @objc static func createModule() -> VinciChallengeMediaViewController {
        let view = VinciChallengeMediaViewController(nibName: nil, bundle: nil)
        let presenter: VinciChallengeMediaPresenterProtocol = VinciChallengeMediaPresenter()
        var interactor: VinciChallengeMediaInteractorProtocol = VinciChallengeMediaInteractor()
        let router: VinciChallengeMediaRouterProtocol = VinciChallengeMediaRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        return view
    }
}
