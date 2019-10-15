//
//  UserDefaults+HiddenExerciseIds.swift
//  Iron
//
//  Created by Karim Abou Zeid on 15.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum HiddenExerciseIdsKeys: String {
        case hiddenExerciseIds
    }
    
    var hiddenExerciseIds: [Int] {
        set {
            self.set(newValue, forKey: HiddenExerciseIdsKeys.hiddenExerciseIds.rawValue)
        }
        get {
            self.array(forKey: HiddenExerciseIdsKeys.hiddenExerciseIds.rawValue) as? [Int] ?? []
        }
    }
}
