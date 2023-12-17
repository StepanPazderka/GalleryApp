//
//  Album.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.11.2021.
//

import Foundation

struct GalleryIndex: Codable {
    var id: UUID = UUID()
    var mainGalleryName: String
    var images: [GalleryImage]
    var albums: [UUID]
    var thumbnailSize: Float? = 200
    var showingAnnotations: Bool? = false
    
    static var empty: Self {
        Self(id: .empty, mainGalleryName: "", images: [GalleryImage](), albums: [UUID](), thumbnailSize: 200, showingAnnotations: false)
    }
    
    enum CodingKeys: String, CodingKey {
        case mainGalleryName = "mainGalleryName"
        case id
        case images
        case albums
    }
}

extension GalleryIndex {
    init(from: GalleryIndexRealm) {
        self.id = UUID(uuidString: from.id)!
        self.images = from.images.map { GalleryImage(from: $0) }
        self.albums = from.albums.map { AlbumIndex(from: $0).id }
        self.mainGalleryName = from.name
        self.showingAnnotations = from.showingAnnotations
        self.thumbnailSize = from.thumbnailSize
    }
}

extension GalleryIndex: Equatable { }
