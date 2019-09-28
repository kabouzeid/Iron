//
//  EntitlementsStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine

class EntitlementsStore: ObservableObject {
    static let shared = EntitlementsStore(userDefaults: UserDefaults.standard)
    
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults) {
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

extension EntitlementsStore {
    var isPro: Bool {
        IAPIdentifiers.pro.contains { entitlements.contains($0) }
    }
}

extension EntitlementsStore {
    func updateEntitlements(response: VerificationResponse) {
        assert(response.status == 0)
        entitlements = response.entitlements
        print("updated entitlements: \(entitlements)")
    }
}
