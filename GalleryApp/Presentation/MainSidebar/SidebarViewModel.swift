//
//  MainSideBarViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.12.2021.
//

import Foundation
import RxSwift

class SideBarViewModel {
    var galleryInteractor: GalleryManager
    
    init(galleryInteractor: GalleryManager) {
        self.galleryInteractor = galleryInteractor
    }
    
    func getAlbums() -> Observable<[SidebarItem]> {
        Observable.create { observer in
            observer.onNext([])
            return Disposables.create()
        }
    }
}
