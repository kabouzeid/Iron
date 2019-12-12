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
        case entitlements
    }
    
    var entitlements: [String] {
        set {
            self.set(newValue, forKey: IAPKeys.entitlements.rawValue)
        }
        get {
            self.array(forKey: IAPKeys.entitlements.rawValue) as? [String] ?? []
        }
    }
}
