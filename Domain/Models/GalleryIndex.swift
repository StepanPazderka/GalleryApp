//
//  Album.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 30.11.2021.
//

import Foundation

struct GalleryIndex: Codable {
    var mainGalleryName: String
    var albums: [AlbumIndex]
}
