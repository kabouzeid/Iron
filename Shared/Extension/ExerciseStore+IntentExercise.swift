//
//  ExerciseStore+IntentExercise.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WorkoutDataKit

extension ExerciseStore {
    func find(intentExercise: IntentExercise) -> Exercise? {
        if let uuidString = intentExercise.identifier, let uuid = UUID(uuidString: uuidString) {
            return find(with: uuid)
        }
        return nil
    }
    
    func resolveIntentExercise(for intentExercise: IntentExercise?, with completion: @escaping (IntentExerciseResolutionResult) -> Void) {
        guard let intentExercise = intentExercise else {
            completion(.needsValue())
            return
        }
        guard let uuidString = intentExercise.identifier, let uuid = UUID(uuidString: uuidString) else {
            completion(.unsupported())
            return
        }
        guard find(with: uuid) != nil else {
            completion(.unsupported())
            return
        }
        completion(.success(with: intentExercise))
    }
}
