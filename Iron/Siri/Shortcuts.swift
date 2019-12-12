//
//  Shortcuts.swift
//  Iron
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Intents
import WorkoutDataKit

enum Shortcuts {
    static func addDefaultSuggestions() {
        let exercises = ExerciseStore.shared.shownExercises.filter { exercise in
            ["Bench Press: Barbell", "Squat: Barbell", "Deadlift: Barbell"].contains(exercise.title)
        }
        
        let prShortcuts = exercises.compactMap { exercise -> INShortcut? in
            let intent = ViewPersonalRecordsIntent()
            intent.exercise = exercise.intentExercise
            return INShortcut(intent: intent)
        }
        
        let oneRepMaxShortcuts = exercises.compactMap { exercise -> INShortcut? in
            let intent = ViewOneRepMaxIntent()
            intent.exercise = exercise.intentExercise
            return INShortcut(intent: intent)
        }
        
        INVoiceShortcutCenter.shared.setShortcutSuggestions(prShortcuts + oneRepMaxShortcuts)
    }
}
