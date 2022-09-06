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
    }
    
    func fetchAlbums() -> Observable<[UUID]> {
        return galleryManager.loadGalleryIndex().map { galleryIndex in
            return galleryIndex.albums
        }
    }
    
    func fetchAlbumButtons() {
        fetchAlbums().subscribe(onNext: { albumsIDs in
            self.albumButtons.append(contentsOf: albumsIDs.map { id in
                if let album = self.galleryManager.loadAlbumIndex(id: id) {
                    return SidebarItem(id: album.id, title: album.name, image: nil)
                } else {
                    return SidebarItem.empty
                }
            })
        }).disposed(by: disposeBag)
    }
    
    func loadAlbums() {
        guard let galleryIndex: GalleryIndex = self.galleryManager.loadGalleryIndex() else { return }
        self.albumButtons = galleryIndex.albums.compactMap {
            SidebarItem(from: AlbumIndex(from: galleryManager.selectedGalleryPath.appendingPathComponent($0.uuidString))!)
        }
    }
    
    func fetchAlbumButtons() -> Observable<[SidebarItem]> {
        self.fetchAlbums().map { albumIDsArray in
            return albumIDsArray.map { albumID in
                if let album = self.galleryManager.loadAlbumIndex(id: albumID) {
                    return SidebarItem(id: album.id, title: album.name, image: nil)
                }
                else {
                    return SidebarItem.empty
                }
            }
        }
    }
    
    func loadGalleryName() -> Observable<String> {
        return galleryManager.loadGalleryIndex().map { galleryIndex in
            return galleryIndex.mainGalleryName
        }
    }
    
    func createAlbum(name: String, parentAlbumID: UUID? = nil,  ID: UUID? = nil, callback: (() -> Void)? = nil) {
        do {
            if let parentAlbumID = parentAlbumID {
                try galleryManager.createAlbum(name: name, parentAlbum: parentAlbumID)
            } else {
                try galleryManager.createAlbum(name: name)
            }
        } catch {
            
        }
        if let callback = callback {
            callback()
        }
    }
    
    func deleteAlbum(index: Int) {
        
    }
}
