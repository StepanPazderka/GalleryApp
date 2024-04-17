//
//  SettingsManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.04.2024.
//

import Foundation

protocol SettingsManager {
	var unsecureStorage: UnsecureStorage { get }
	func getSelectedLibraryName() -> String
}
