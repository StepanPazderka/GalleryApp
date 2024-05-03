//
//  SettingsManager.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 17.04.2024.
//

import Foundation
import RxSwift

protocol SettingsManager: AnyObject {
	var unsecureStorage: UnsecureStorage { get }
	var selectedGalleryName: String! { get }
	func getSelectedLibraryName() -> String
	func getCurrentlySelectedGalleryIDAsObservable() -> Observable<String>
	func set(key: SettingsKey, value: String)
}
