//
//  Everkinetic.swift
//  IronData
//
//  Created by Karim Abou Zeid on 22.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

class Everkinetic {
    static var resourcesURL: URL {
        Bundle(for: Self.self).bundleURL.appendingPathComponent("everkinetic-data")
    }
}
