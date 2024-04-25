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
    typealias Identity = String
    
    var identity: String {
		return id.uuidString
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

extension GalleryImage: Equatable { 
	static func ==(lhs: GalleryImage, rhs: GalleryImage) -> Bool {
		return lhs.fileName == rhs.fileName && lhs.title == rhs.title && lhs.date == rhs.date
	}
}
