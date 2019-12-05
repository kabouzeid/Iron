//
//  SettingsStore+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension SettingsStore {
    static func migrateToAppGroupIfNecessary() {
        let didMigrateSettingsToAppGroup = "didMigrateSettingsToAppGroup"
        guard !UserDefaults.standard.bool(forKey: didMigrateSettingsToAppGroup) else { return }
        print("attempt to migrate settings to app group")
        guard let groupUserDefaults = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            fatalError("could not create user defaults for group suite \(FileManager.appGroupIdentifier)")
        }
        
        let keys = UserDefaults.SettingsKeys.allCases.map { $0.rawValue }
        for key in keys {
            if let value = UserDefaults.standard.value(forKey: key) {
                groupUserDefaults.set(value, forKey: key)
            }
        }
        UserDefaults.standard.set(true, forKey: didMigrateSettingsToAppGroup)
        print("migrated settings to app group")
    }
}
