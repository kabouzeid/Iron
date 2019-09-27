//
//  UserDefaults+IAP.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum IAPKeys: String {
        case proExpirationDate
        case purchasedProLifetime
    }
    
    var proExpirationDate: Date? {
        set {
            self.set(newValue, forKey: IAPKeys.proExpirationDate.rawValue)
        }
        get {
            self.object(forKey: IAPKeys.proExpirationDate.rawValue) as? Date
        }
    }
    
    var purchasedProLifetime: Bool {
        set {
            self.set(newValue, forKey: IAPKeys.purchasedProLifetime.rawValue)
        }
        get {
            self.object(forKey: IAPKeys.purchasedProLifetime.rawValue) as? Bool ?? false
        }
    }
}
