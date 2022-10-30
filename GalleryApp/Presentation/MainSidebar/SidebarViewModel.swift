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
        galleryManager.selectedGalleryIndexRelay
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
    
    func fetchAlbumButtons() -> Observable<[SidebarItem]> {
        self.fetchAlbums().map { albumIDsArray in
            return albumIDsArray.map { albumID in
                if let album = self.galleryManager.loadAlbumIndex(id: albumID) {
                    var thumbnailImage: UIImage?
                    if !album.thumbnail.isEmpty {
                        thumbnailImage = UIImage(contentsOfFile: self.galleryManager.selectedGalleryPath.appendingPathComponent(album.thumbnail).relativePath)
                    }
                    return SidebarItem(id: album.id, title: album.name, image: thumbnailImage?.resized(to: CGSize(width: 25.5, height: 25.5)) ?? nil) // TODO: - Resizing
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
        self.galleryManager.delete(album: selectedAlbumForDeletion.identifier)
    }
}
