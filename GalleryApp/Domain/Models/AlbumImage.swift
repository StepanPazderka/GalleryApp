//
//  GalleryPicture.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.12.2020.
//

import Foundation
import UIKit

struct AlbumImage: Codable {
    var fileName: String
    var date: Date
    var title: String?
    
    internal init(fileName: String, date: Date, title: String? = nil) {
        self.fileName = fileName
        self.date = date
        self.title = title
    }
}
