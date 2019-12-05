//
//  UserDefaults+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 06.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    func migrate(to: UserDefaults) {
        let dict = dictionaryRepresentation()
        to.setValuesForKeys(dict)
        dict.keys.forEach { removeObject(forKey: $0) }
    }
}

extension UserDefaults {
    func migrateToAppGroupIfNecessary() {
        guard let groupUserDefaults = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            fatalError("could not create user defaults for group suite \(FileManager.appGroupIdentifier)")
        }
        
        let didMigrateToAppGroups = "didMigrateToAppGroups"
        if !bool(forKey: didMigrateToAppGroups) {
            migrate(to: groupUserDefaults)
            set(true, forKey: didMigrateToAppGroups)
        }
    }
}
