//
//  IAPIdentifiers.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct IAPIdentifiers {
    static let pro = Self.proSubscriptions + [Self.proLifetime]
    static let proSubscriptions = [Self.proMonthly, Self.proYearly]
    
    static let proMonthly = "pro_monthly"
    static let proYearly = "pro_yearly"
    
    static let proLifetime = "pro_life" // pro_lifetime deleted by accident
}
