//
//  MainSideBarViewModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 25.12.2021.
//

import Foundation
import RxSwift

class SidebarViewModel {
    
    // MARK: -- Properties
    private var galleryManager: GalleryManager
    var albumButtons = [SidebarItem]()
    
    let disposeBag = DisposeBag()
    
    init(galleryInteractor: GalleryManager) {
        self.galleryManager = galleryInteractor
        
        bindAlbums()
    }
    
    func galleryIndex() -> Observable<GalleryIndex> {
        galleryManager.selectedGalleryIndexRelay.asObservable()
    }
    
    func bindAlbums() {
        galleryManager.selectedGalleryIndexRelay.subscribe(onNext: { gallery in
            self.albumButtons = gallery.albums.compactMap { albumID in
                if let albumIndex = self.galleryManager.loadAlbumIndex(id: albumID) {
                    return SidebarItem(from: albumIndex)
                }
                return nil
            }
        }).disposed(by: disposeBag)
    }
    
    func fetchAlbums() -> Observable<[UUID]> {
        return galleryManager.loadGalleryIndex().map { galleryIndex in
            return galleryIndex.albums
        }
    }
    
    func loadSidebarContent() -> Observable<[SidebarSection]> {
        galleryIndex().map { galleryIndex in
            let mainButonsSection = SidebarSection(category: "Main", items: [
                SidebarItem(id: UUID(), title: "All Photos", image: nil, buttonType: .allPhotos)
            ])
            let albumButtons = SidebarSection(category: "Albums", items: galleryIndex.albums.compactMap { albumID in
                if let album = self.galleryManager.loadAlbumIndex(id: albumID) {
                    return SidebarItem(id: UUID(uuidString: albumID.uuidString), title: album.name, image: nil, buttonType: .album)
                } else {
                    return nil
                }
            })
            return [mainButonsSection, albumButtons]
        }
    }
    
    func loadGalleryName() -> Observable<String> {
        return galleryManager.loadGalleryIndex().map { galleryIndex in
            return galleryIndex.mainGalleryName
        }
    }
    
    func createAlbum(name: String, parentAlbumID: UUID? = nil,  ID: UUID? = nil) {
        do {
            if let parentAlbumID = parentAlbumID {
                try galleryManager.createAlbum(name: name, parentAlbum: parentAlbumID)
            } else {
                try galleryManager.createAlbum(name: name)
            }
        } catch {
            
        }
    }
    
    func deleteAlbum(index: Int) {
        let selectedAlbumForDeletion = self.albumButtons[index - 1]
        if let id = selectedAlbumForDeletion.identifier {
            self.galleryManager.delete(album: id)
        }
    }
}
