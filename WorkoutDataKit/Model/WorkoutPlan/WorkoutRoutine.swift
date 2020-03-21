//
//  WorkoutPlan.swift
//  WorkoutDataKit
//
//  Created by Karim Abou Zeid on 21.12.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import CoreData

public class WorkoutRoutine: NSManagedObject {
    public var fallbackTitle: String? {
        guard let index = workoutPlan?.workoutRoutines?.index(of: self), index != NSNotFound else { return nil }
        guard let letters = toLetters(from: index) else { return nil }
        return "Routine \(letters)"
    }
    
    private func toLetters(from index: Int) -> String? {
        guard index >= 0 else { return nil }

        let quotient: Int = index / 26
        let remainder: Int = index % 26
        
        guard let scalar = UnicodeScalar(Int(UnicodeScalar("A").value) + remainder) else {
            assertionFailure("This should never happen")
            return nil
        }
        let letter = String(Character(scalar))
        
        if quotient == 0 {
            return letter
        }
        
        guard let prefix = toLetters(from: quotient - 1) else { return nil }
        return prefix + letter
    }

    
    public var displayTitle: String {
        title ?? fallbackTitle ?? "Workout Routine"
    }
    
    public func subtitle(in exercises: [Exercise]) -> String {
        let s = workoutRoutineExercises?
            .compactMap { $0 as? WorkoutRoutineExercise }
            .compactMap { $0.exercise(in: exercises)?.title }
            .joined(separator: ", ") ?? ""
        
        return s.isEmpty ? "Empty" : s
    }
    
    public func createWorkout(context: NSManagedObjectContext) -> Workout {
        let workout = Workout(context: context)
        workout.uuid = UUID()
        
        if let workoutRoutineExercises = workoutRoutineExercises?.compactMap({ $0 as? WorkoutRoutineExercise }) {
            // copy the exercises
            for workoutRoutineExercise in workoutRoutineExercises {
                let workoutExercise = WorkoutExercise(context: context)
                workout.addToWorkoutExercises(workoutExercise)
                workoutExercise.exerciseUuid = workoutRoutineExercise.exerciseUuid
                
                if let workoutRoutineSets = workoutRoutineExercise.workoutRoutineSets?.compactMap({ $0 as? WorkoutRoutineSet }) {
                    // copy the sets
                    for workoutRoutineSet in workoutRoutineSets {
                        let workoutSet = WorkoutSet(context: context)
                        workoutExercise.addToWorkoutSets(workoutSet)
                        workoutSet.isCompleted = false
                        workoutSet.plannedRepetitionsMax = workoutRoutineSet.repetitionsMax
                        workoutSet.plannedRepetitionsMin = workoutRoutineSet.repetitionsMin
                    }
                }
            }
        }
        
        addToWorkouts(workout)
        return workout
    }
}
