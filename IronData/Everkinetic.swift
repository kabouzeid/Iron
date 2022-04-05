//
//  Everkinetic.swift
//  IronData
//
//  Created by Karim Abou Zeid on 22.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

class Everkinetic {
    static var bundle: Bundle {
        Bundle(for: Self.self)
    }
    
    static var resourcesURL: URL {
        Everkinetic.bundle.bundleURL.appendingPathComponent("everkinetic-data")
    }
}
