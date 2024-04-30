//
//  PersistanceManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 28.04.2024.
//

import Foundation
import RealmSwift

enum PersistanceError: LocalizedError {
	case cantLoad
	case cantSave
	case cantDelete
	
	public var errorDescription: String? {
		switch self {
		case .cantLoad:
			return NSLocalizedString("Cant load objects from the database", comment: "")
		case .cantSave:
			return NSLocalizedString("Cant save objects to the database", comment: "")
		case .cantDelete:
			return NSLocalizedString("Cant delete objects from the database", comment: "")
		}
	}
}

protocol PersistanceManager {
	associatedtype PersistanceModelType
	
	func save(_: PersistanceModelType) throws
	func load() throws -> [PersistanceModelType]
	func delete(_ objectsForDeletion: [PersistanceModelType])
}
