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
    enum VerificationResponseError: Error {
         case subscriptionHasNoExpirationDate
     }
     
    func updateEntitlements(response: VerificationResponse) throws {
        // TODO update code with own server response
        let proSubscriptionExpirationDate = try response.latestReceiptInfo
            .filter { $0.cancellationDate == nil }
            .filter { $0.productIdentifier == IAPIdentifiers.proMonthly }
            .map { receipt throws -> Date in
                guard let expirationDate = receipt.subscriptionExpirationDate else {
                    throw VerificationResponseError.subscriptionHasNoExpirationDate
                }
                return expirationDate
        }
        .max()
        if let expires = proSubscriptionExpirationDate, expires >= Date() {
            print("Parsed pro expiration date: \(expires)")
            entitlements = [IAPIdentifiers.proMonthly]
        } else {
            entitlements = []
        }
        print("entitlements: \(entitlements)")
    }
}
