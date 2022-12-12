//
//  AlbumScreenModel.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.11.2022.
//

import Foundation

struct AlbumScreenModel {
    var id = UUID()
    var name: String
    var images: [AlbumImage]
    var thumbnail: String
    var thumbnailsSize: Float = 200
}
