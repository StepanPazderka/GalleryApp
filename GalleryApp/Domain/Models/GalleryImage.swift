//
//  GalleryPicture.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 20.12.2020.
//

import Foundation
import UIKit
import RxDataSources
import Realm
import RealmSwift

struct GalleryImage: Codable {
    var fileName: String
    var date: Date
    var title: String?
    var id = UUID()
    
    static let empty = Self(fileName: "", date: Date(), title: "")
    
    internal init(fileName: String, date: Date, title: String? = nil) {
        self.fileName = fileName
        self.date = date
        self.title = title
        let fileNameAsURL = URL(string: fileName)!.deletingPathExtension()
        self.id = UUID(uuidString: fileNameAsURL.relativePath)!
    }
}

extension GalleryImage: IdentifiableType {
    typealias Identity = UUID
    
    var identity: UUID {
        return id
    }
}

// MARK: - Realm compatibility
extension GalleryImage {
    init(from: GalleryImageRealm) {
        self.fileName = from.fileName
        self.date = from.date
        self.title = from.title
        self.id = UUID(uuidString: from.id) ?? UUID()
    }
}

extension GalleryImage: Equatable { }

extension GalleryImage: Hashable { }
