//
//  VerificationResponse.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct VerificationResponse: Codable {
    let status: Int
    let entitlements: [String]
}
