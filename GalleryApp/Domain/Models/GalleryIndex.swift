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
    
    static var empty: Self {
        Self(mainGalleryName: "", images: [AlbumImage](), albums: [UUID]())
    }
}
