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
    var images: [AlbumImage]
    var albums: [UUID]
    var thumbnailSize: Float? = 200
    var showingAnnotations: Bool? = false
    
    static var empty: Self {
        Self(mainGalleryName: "", images: [AlbumImage](), albums: [UUID](), thumbnailSize: 200, showingAnnotations: false)
    }
}

extension GalleryIndex: Equatable { }
