//
//  EntitlementStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import os.log

final class EntitlementStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    // product identifiers the user is entitled to
    var entitlements: [String] {
        get {
            userDefaults.entitlements
        }
        set {
            self.objectWillChange.send()
            userDefaults.entitlements = newValue
        }
    }
}

extension EntitlementStore {
    var isPro: Bool {
        IAPIdentifiers.pro.contains { entitlements.contains($0) }
    }
}

extension EntitlementStore {
    func updateEntitlements(response: VerificationResponse) {
        assert(response.status == 0)
        entitlements = response.entitlements
        os_log("Updated entitlements: %@", log: .iap, type: .debug, response.entitlements)
    }
}

#if DEBUG
extension EntitlementStore {
    static let mockPro: EntitlementStore = {
        let store = EntitlementStore(userDefaults: UserDefaults(suiteName: "mock_pro")!)
        store.entitlements = ["pro_monthly"]
        return store
    }()

    static let mockNoPro: EntitlementStore = {
        let store = EntitlementStore(userDefaults: UserDefaults(suiteName: "mock_no_pro")!)
        store.entitlements = []
        return store
    }()
}
#endif
