//
//  WorkoutExercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

class WorkoutExercise: NSManagedObject {
    static func historyFetchRequest(of exerciseUuid: UUID?, until: Date?) -> NSFetchRequest<WorkoutExercise> {
        let request: NSFetchRequest<WorkoutExercise> = WorkoutExercise.fetchRequest()
        let basePredicate = NSPredicate(format: "\(#keyPath(WorkoutExercise.workout.isCurrentWorkout)) != %@ AND \(#keyPath(WorkoutExercise.exerciseUuid)) == %@", NSNumber(booleanLiteral: true), (exerciseUuid ?? UUID()) as CVarArg)
        if let until = until {
            let untilPredicate = NSPredicate(format: "\(#keyPath(WorkoutExercise.workout.start)) < %@", until as NSDate)
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, untilPredicate])
        } else {
            request.predicate = basePredicate
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutExercise.workout?.start, ascending: false)]
        return request
    }
    
    var historyFetchRequest: NSFetchRequest<WorkoutExercise> {
        WorkoutExercise.historyFetchRequest(of: exerciseUuid, until: workout?.start)
    }
    
    // MARK: Derived properties
    
    func exercise(in exercises: [Exercise]) -> Exercise? {
        ExerciseStore.find(in: exercises, with: exerciseUuid)
    }
    
    var isCompleted: Bool? {
        guard let workoutSets = workoutSets else { return nil }
        return !workoutSets
            .compactMap { $0 as? WorkoutSet }
            .contains { !$0.isCompleted }
    }

    var numberOfCompletedSets: Int? {
        workoutSets?
            .compactMap { $0 as? WorkoutSet }
            .filter { $0.isCompleted }
            .count
    }

    var numberOfCompletedRepetitions: Int? {
        workoutSets?
            .compactMap { $0 as? WorkoutSet }
            .reduce(0, { (count, workoutSet) -> Int in
                count + (workoutSet.isCompleted ? Int(workoutSet.repetitions) : 0)
            })
    }

    var totalCompletedWeight: Double? {
        workoutSets?
            .compactMap { $0 as? WorkoutSet }
            .reduce(0, { (weight, workoutSet) -> Double in
                weight + (workoutSet.isCompleted ? workoutSet.weight * Double(workoutSet.repetitions) : 0)
            })
    }

    private var cancellable: AnyCancellable?
}

// MARK: Observable
extension WorkoutExercise {
    override func awakeFromFetch() {
        super.awakeFromFetch() // important
        initChangeObserver()
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert() // important
        initChangeObserver()
    }
    
    private func initChangeObserver() {
        cancellable = managedObjectContext?.publisher
            .filter { changed in
                changed.contains { managedObject in
                    if let workout = managedObject as? Workout {
                        return workout.objectID == self.workout?.objectID
                    }
                    if let workoutSet = managedObject as? WorkoutSet {
                        return workoutSet.workoutExercise?.objectID == self.objectID
                    }
                    return managedObject.objectID == self.objectID
                }
            }
            .sink { _ in self.objectWillChange.send() }
    }
}

// MARK: Encodable
extension WorkoutExercise: Encodable {
    private enum CodingKeys: String, CodingKey {
        case exerciseUuid
        case exerciseName
        case comment
        case sets
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(exerciseUuid, forKey: .exerciseUuid)
        try container.encodeIfPresent(exercise(in: ExerciseStore.shared.exercises)?.title, forKey: .exerciseName)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(workoutSets?.array.compactMap { $0 as? WorkoutSet }, forKey: .sets)
    }
}
