//
//  GallerySection.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 14.03.2021.
//

import Foundation

struct GalleryFolder: Codable {
    var name: String
    var images: [URL]
}
