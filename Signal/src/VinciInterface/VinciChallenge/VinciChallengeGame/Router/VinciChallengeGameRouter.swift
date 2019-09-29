//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import UIKit


class VinciChallengeGameRouter: NSObject, VinciChallengeGameRouterProtocol {
    static func createModule(gameState: GameState) -> VinciChallengeGameViewController {
        let view = VinciChallengeGameViewController(gameState: gameState, nibName: nil, bundle: nil)
        let presenter: VinciChallengeGamePresenterProtocol = VinciChallengeGamePresenter()
        var interactor: VinciChallengeGameInteractorProtocol = VinciChallengeGameInteractor()
        let router: VinciChallengeGameRouterProtocol = VinciChallengeGameRouter()
        
        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter
        
        return view
    }
}
