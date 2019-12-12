//
//  View1RMIntentHandler.swift
//  IronIntents
//
//  Created by Karim Abou Zeid on 08.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Intents
import CoreData
import WorkoutDataKit

class ViewOneRepMaxIntentHandler: NSObject, ViewOneRepMaxIntentHandling {
    func handle(intent: ViewOneRepMaxIntent, completion: @escaping (ViewOneRepMaxIntentResponse) -> Void) {
        guard let intentExercise = intent.exercise,
            let exercise = ExerciseStore.shared.find(intentExercise: intentExercise) else {
                completion(.init(code: .failure, userActivity: nil))
                return
        }

        let request: NSFetchRequest<WorkoutSet> = WorkoutSet.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(WorkoutSet.workoutExercise.exerciseUuid)) == %@", exercise.uuid as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSet.workoutExercise?.workout?.start, ascending: false)]
        guard let sets = try? WorkoutDataStorage.shared.persistentContainer.viewContext.fetch(request) else {
            completion(.init(code: .failure, userActivity: nil))
            return
        }

        let maxRepetitionsOneRepMax = SettingsStore.shared.maxRepetitionsOneRepMax
        let oneRepMaxSets = sets.compactMap { workoutSet -> (WorkoutSet, Double)? in
            guard let oneRepMax = workoutSet.estimatedOneRepMax(maxReps: maxRepetitionsOneRepMax) else { return nil }
            return (workoutSet, oneRepMax)
        }
        guard let oneRepMaxSet = oneRepMaxSets.max(by: { $0.1 < $1.1 }) else {
            completion(.failureNoOneRepMax(exercise: intentExercise))
            return
        }

        let weightUnit = SettingsStore.shared.weightUnit
        let oneRepMaxMeasurement = Measurement(value: oneRepMaxSet.1, unit: UnitMass.kilograms).converted(to: weightUnit.unit)
        let intentSet = IntentWorkoutSet(workoutSet: oneRepMaxSet.0, weightUnit: weightUnit)
        
        completion(.success(exercise: intentExercise, oneRepMax: oneRepMaxMeasurement, set: intentSet))
    }
    
    func resolveExercise(for intent: ViewOneRepMaxIntent, with completion: @escaping (IntentExerciseResolutionResult) -> Void) {
        ExerciseStore.shared.resolveIntentExercise(for: intent.exercise, with: completion)
    }
    
    func provideExerciseOptions(for intent: ViewOneRepMaxIntent, with completion: @escaping ([IntentExercise]?, Error?) -> Void) {
        completion(ExerciseStore.shared.shownExercises.map { $0.intentExercise }, nil)
    }
}
