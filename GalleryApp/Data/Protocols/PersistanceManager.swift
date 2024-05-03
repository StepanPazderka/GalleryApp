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
	associatedtype AssociatedPersistableModelType
	
	func save(_ objectsToPersist: [any PersistableModelConvertible]) throws
	func save(_ objectToPersist: any PersistableModelConvertible) throws
	func load(_ object: any PersistableModelConvertible) throws -> AssociatedPersistableModelType
	func update(_ objectsToPersist: [any PersistableModelConvertible]) throws
	func update(_ objectToPersist: any PersistableModelConvertible) throws
	func delete(_ objectsForDeletion: [any PersistableModelConvertible])
}
