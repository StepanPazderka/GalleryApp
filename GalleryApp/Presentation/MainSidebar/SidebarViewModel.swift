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
    
    let disposeBag = DisposeBag()
    
    init(galleryInteractor: GalleryManager) {
        self.galleryManager = galleryInteractor
        
    }
    
    func loadGalleryIndex() -> Observable<GalleryIndex> {
        galleryManager.selectedGalleryIndexRelay.asObservable()
    }
    
    func fetchAlbums() -> Observable<[UUID]> {
        return galleryManager.loadGalleryIndex().map { galleryIndex in
            return galleryIndex.albums
        }
    }
    
    func duplicateAlbum(id: UUID) {
        if let album: AlbumIndex = self.galleryManager.loadAlbumIndex(id: id) {
            self.galleryManager.dubplicateAlbum(index: album)
        }
    }
    
    func loadSidebarContent() -> Observable<[SidebarSection]> {
        loadGalleryIndex().map { galleryIndex in
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
    
    func deleteAlbum(id: UUID) {
        self.galleryManager.delete(album: id)
    }
}
