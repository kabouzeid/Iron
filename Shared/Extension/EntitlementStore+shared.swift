//
//  EntitlementStore+shared.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension EntitlementStore {
    static let shared = EntitlementStore(userDefaults: UserDefaults.appGroup)
}
