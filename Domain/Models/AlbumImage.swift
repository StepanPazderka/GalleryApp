//
//  GalleryPicture.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.12.2020.
//

import Foundation
import UIKit

struct AlbumImage: Codable {
    internal init(fileName: String, date: Date) {
        self.fileName = fileName
        self.date = date
    }
    
    var fileName: String
    var date: Date
}
