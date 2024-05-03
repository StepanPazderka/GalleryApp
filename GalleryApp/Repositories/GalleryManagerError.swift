//
//  GalleryManagerError.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 29.11.2023.
//

import Foundation

enum GalleryManagerError: Error {
    case cantWriteImage
    case imageAlreadyInAlbum
    case cantUpdateAlbum
    case cantReadAlbum
    case notFound
	case unknown
}

extension GalleryManagerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cantWriteImage:
            return "Database cant write record for image"
        case .imageAlreadyInAlbum:
            return "Image already exists in selected album"
        case .cantUpdateAlbum:
            return "Cant update album"
        case .cantReadAlbum:
            return "Cant read album from database"
        case .notFound:
            return "Element was not found"
		case .unknown:
			return "Unknown error"
        }
    }
}
