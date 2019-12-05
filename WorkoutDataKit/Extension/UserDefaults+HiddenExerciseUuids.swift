//
//  UserDefaults+HiddenExerciseUuids.swift
//  Iron
//
//  Created by Karim Abou Zeid on 15.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum HiddenExerciseUuidsKeys: String {
        case hiddenExerciseIds // TODO: previous name, remove in future
        case hiddenExerciseUuids
    }
    
    var hiddenExerciseUuids: [UUID] {
        set {
            self.set(newValue.map { $0.uuidString }, forKey: HiddenExerciseUuidsKeys.hiddenExerciseUuids.rawValue)
        }
        get {
            (self.array(forKey: HiddenExerciseUuidsKeys.hiddenExerciseUuids.rawValue) as? [String])?.compactMap { UUID(uuidString: $0) } ?? []
        }
    }
}
