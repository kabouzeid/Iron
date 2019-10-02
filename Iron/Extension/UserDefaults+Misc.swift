//
//  UserDefaults+Misc.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum MiscKeys: String {
        case finishedTrainingCount
    }
    
    var finishedTrainingCount: Int {
        set {
            self.set(newValue, forKey: MiscKeys.finishedTrainingCount.rawValue)
        }
        get {
            self.integer(forKey: MiscKeys.finishedTrainingCount.rawValue)
        }
    }
}
