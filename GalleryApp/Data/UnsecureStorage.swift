//
//  UnsecureStorage.swift
//  GalleryApp
//
//  Created by Štěpán Pazderka on 06.06.2022.
//

import Foundation

class UnsecureStorage {
    let userDefaults: UserDefaults = UserDefaults.standard
    
    func load<T>(key: SettingsKey) -> T? {
//        userDefaults.string(forKey: key.rawValue)
        return userDefaults.object(forKey: key.rawValue) as? T
    }
    
    func load<T>(key: SettingsKey, type: T.Type) -> T? {
//        userDefaults.string(forKey: key.rawValue)
        return userDefaults.object(forKey: key.rawValue) as? T
    }
    
    func save<T>(key: SettingsKey, value: T) {
        userDefaults.set(value, forKey: key.rawValue)
    }
}
