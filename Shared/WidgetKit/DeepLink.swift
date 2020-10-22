//
//  DeepLink.swift
//  Iron
//
//  Created by Karim Abou Zeid on 12.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum DeepLink: String {
    case startWorkout
}

extension DeepLink {
    static let URLScheme = "iron"
    
    static func url(for deepLink: DeepLink) -> URL {
        URL(string: "\(URLScheme)://\(deepLink.rawValue)")!
    }
}

extension URL {
    var isDeepLinkURL: Bool {
        scheme == DeepLink.URLScheme
    }
}
