//
//  GalleryPicture.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.12.2020.
//

import Foundation
import UIKit
import RxDataSources

struct GalleryImage: Codable {
    var fileName: String
    var date: Date
    var title: String?
    var id = UUID()
    
    internal init(fileName: String, date: Date, title: String? = nil) {
        self.fileName = fileName
        self.date = date
        self.title = title
    }
}

extension GalleryImage: IdentifiableType {
    typealias Identity = UUID
    
    var identity: UUID {
        return id
    }
}

extension GalleryImage: Equatable { }
