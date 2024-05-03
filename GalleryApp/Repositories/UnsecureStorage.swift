//
//  UnsecureStorage.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 06.06.2022.
//

import Foundation
import RxSwift

enum UnsecureStorageError: Error {
	case noValueForKey(_: String)
}

class UnsecureStorage {
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func load<T>(key: SettingsKey) -> T? {
        return userDefaults.object(forKey: key.rawValue) as? T
    }
    
    func load<T>(key: SettingsKey, type: T.Type) -> T? {
        return userDefaults.object(forKey: key.rawValue) as? T
    }
    
    func save<T>(key: SettingsKey, value: T) {
        userDefaults.set(value, forKey: key.rawValue)
    }
	
	func getAsObservable<T>(key: SettingsKey) -> Observable<T> {
		UserDefaults.standard.rx.observe(T.self, key.rawValue).flatMap { value -> Observable<T> in
			guard let unwrappedValue = value else {
				self.save(key: .selectedGallery, value: "00")
				return Observable.error(UnsecureStorageError.noValueForKey(key.rawValue))
			}
			return Observable.just(unwrappedValue)
		}
	}
}
