//
//  ProStatusStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 26.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine

class ProStatusStore: ObservableObject {
    static let shared = ProStatusStore(userDefaults: UserDefaults.standard)
    
    let objectWillChange = ObservableObjectPublisher()
    
    private var userDefaults: UserDefaults
    
    private init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    var isPro: Bool {
        if let expiration = proSubscriptionExpirationDate {
            return proLifetime || expiration >= Date()
        }
        return proLifetime
    }
    
    var proSubscriptionExpirationDate: Date? {
        get {
            userDefaults.proExpirationDate
        }
        set {
            self.objectWillChange.send()
            userDefaults.proExpirationDate = newValue
        }
    }
    
    var proLifetime: Bool {
        get {
            userDefaults.purchasedProLifetime
        }
        set {
            self.objectWillChange.send()
            userDefaults.purchasedProLifetime = newValue
        }
    }
}

extension ProStatusStore {
    enum VerificationResponseError: Error {
         case subscriptionHasNoExpirationDate
     }
     
    func updateProExpirationDate(response: VerificationResponse) throws {
         try proSubscriptionExpirationDate = response.latestReceiptInfo
             .filter { $0.cancellationDate == nil }
             .filter { $0.productIdentifier == IAPIdentifiers.proMonthly }
             .map { receipt throws -> Date in
                 guard let expirationDate = receipt.subscriptionExpirationDate else {
                     throw VerificationResponseError.subscriptionHasNoExpirationDate
                 }
                 return expirationDate
             }
             .max()
         print("Updated the pro expiration date to \(UserDefaults.standard.proExpirationDate?.description ?? "nil")")
     }
     
    func updateProLifetime(response: VerificationResponse) {
        // TODO
     }
}
