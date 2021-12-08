//
//  GallerySection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.03.2021.
//

import Foundation

struct AlbumIndex: Codable {
    var name: String
    var images: [String]?
    var thumbnail: String

    internal init(name: String, images: [String], thumbnail: String) {
        self.name = name
        self.images = images
        self.thumbnail = thumbnail
    }

    init?(from entity: URL) {
        let loadedAlbum = IndexInteractor.loadIndex(folder: entity)
        if let album = loadedAlbum {
            self.name = album.name
            self.images = album.images
            self.thumbnail = album.thumbnail
        } else {
            return nil
        }
    }
}
