//
//  AlbumListRouter.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 24.09.2023.
//

import Foundation

class AlbumListRouter {
    
    weak var viewController: AlbumsListViewController?
    
    func start(viewController: AlbumsListViewController) {
        self.viewController = viewController
    }
    
    func onCancelTap() {
        viewController?.dismiss(animated: true)
    }
}
