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
            if let uuids = self.array(forKey: HiddenExerciseUuidsKeys.hiddenExerciseUuids.rawValue) as? [String] {
                return uuids.compactMap { UUID(uuidString: $0) }
            }
            
            // TODO: remove in future
            print("Trying to decode hiddenExerciseUuids as Ids")
            if let ids = self.array(forKey: HiddenExerciseUuidsKeys.hiddenExerciseIds.rawValue) as? [Int] {
                let uuids = ids.compactMap { id in ExerciseStore.shared.exercises.first { exercise in exercise.everkineticId == id }?.uuid }
                self.hiddenExerciseUuids = uuids
                return uuids
            }
            
            return []
        }
    }
}
