//
//  EntitlementStore+Migrate.swift
//  Iron
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import os.log

extension EntitlementStore {
    static func migrateToAppGroupIfNecessary() {
        let didMigrateEntitlementsToAppGroup = "didMigrateEntitlementsToAppGroup"
        guard !UserDefaults.standard.bool(forKey: didMigrateEntitlementsToAppGroup) else { return }
        os_log("Migrating entitlements to app group", log: .migration, type: .default)
        guard let groupUserDefaults = UserDefaults(suiteName: FileManager.appGroupIdentifier) else {
            fatalError("Could not create user defaults for group suite \(FileManager.appGroupIdentifier)")
        }
        
        let entitlementKey = UserDefaults.IAPKeys.entitlements.rawValue
        if let value = UserDefaults.standard.value(forKey: entitlementKey) {
            groupUserDefaults.set(value, forKey: entitlementKey)
        }

        UserDefaults.standard.set(true, forKey: didMigrateEntitlementsToAppGroup)
        os_log("Successfully migrated entitlements to app group", log: .migration, type: .info)
    }
}
