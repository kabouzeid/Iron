//
//  DeveloperSettings.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

#if DEBUG

import SwiftUI
import WorkoutDataKit

struct DeveloperSettings: View {
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    var body: some View {
        Form {
            Button("Create default workout plans") {
                createDefaultWorkoutPlans()
            }
            
            Toggle("Pro", isOn: isPro)
        }.navigationBarTitle("Developer", displayMode: .inline)
    }
    
    var isPro: Binding<Bool> {
        Binding {
            entitlementStore.isPro
        } set: { newValue in
            if newValue {
                entitlementStore.entitlements = IAPIdentifiers.pro
            } else {
                entitlementStore.entitlements = []
            }
        }

    }
}

func toUuid(_ id: Int) -> UUID? {
    ExerciseStore.shared.exercises.first { $0.everkineticId == id }?.uuid
}

func niceWeight(weight: Double, unit: WeightUnit) -> Double {
    let weightInUnit = WeightUnit.convert(weight: weight, from: .metric, to: unit)
    let nice = weightInUnit - weightInUnit.truncatingRemainder(dividingBy: unit.barbellIncrement)
    return WeightUnit.convert(weight: nice, from: unit, to: .metric)
}

func createDefaultWorkoutPlans() {
    let context = WorkoutDataStorage.shared.persistentContainer.viewContext
    let unit = SettingsStore.shared.weightUnit

    let create5x5 = { (weight: Double) -> [WorkoutRoutineSet] in
        (0..<5).map { _ -> WorkoutRoutineSet in
            let set = WorkoutRoutineSet.create(context: context)
            set.minRepetitionsValue = 5
            set.maxRepetitionsValue = 5
            return set
        }
    }

    let workoutRoutineExerciseSquatA = WorkoutRoutineExercise.create(context: context)
    workoutRoutineExerciseSquatA.exerciseUuid = toUuid(122) // squat
    workoutRoutineExerciseSquatA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 120, unit: unit)))

    let workoutRoutineExerciseBenchA = WorkoutRoutineExercise.create(context: context)
    workoutRoutineExerciseBenchA.exerciseUuid = toUuid(42) // bench
    workoutRoutineExerciseBenchA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 80, unit: unit)))

    let workoutRoutineExerciseRowA = WorkoutRoutineExercise.create(context: context)
    workoutRoutineExerciseRowA.exerciseUuid = toUuid(298) // row
    workoutRoutineExerciseRowA.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 60, unit: unit)))

    let workoutRoutineA = WorkoutRoutine.create(context: context)
    workoutRoutineA.title = "Workout A"
    workoutRoutineA.workoutRoutineExercises = NSOrderedSet(arrayLiteral: workoutRoutineExerciseSquatA, workoutRoutineExerciseBenchA, workoutRoutineExerciseRowA)

    let workoutRoutineExerciseSquatB = WorkoutRoutineExercise.create(context: context)
    workoutRoutineExerciseSquatB.exerciseUuid = toUuid(122) // squat
    workoutRoutineExerciseSquatB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 120, unit: unit)))

    let workoutRoutineExerciseBenchB = WorkoutRoutineExercise.create(context: context)
    workoutRoutineExerciseBenchB.exerciseUuid = toUuid(9001) // press
    workoutRoutineExerciseBenchB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 65, unit: unit)))

    let workoutRoutineExerciseRowB = WorkoutRoutineExercise.create(context: context)
    workoutRoutineExerciseRowB.exerciseUuid = toUuid(99) // deadlift
    workoutRoutineExerciseRowB.workoutRoutineSets = NSOrderedSet(array: create5x5(niceWeight(weight: 140, unit: unit)))

    let workoutRoutineB = WorkoutRoutine.create(context: context)
    workoutRoutineB.title = "Workout B"
    workoutRoutineB.workoutRoutineExercises = NSOrderedSet(arrayLiteral: workoutRoutineExerciseSquatB, workoutRoutineExerciseBenchB, workoutRoutineExerciseRowB)

    let workoutPlan = WorkoutPlan.create(context: context)
    workoutPlan.title = "StrongLifts 5x5"
    workoutPlan.workoutRoutines = NSOrderedSet(arrayLiteral: workoutRoutineA, workoutRoutineB)
}

struct DeveloperSettings_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperSettings()
    }
}

#endif
