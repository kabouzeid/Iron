//
//  Workout.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

class Workout: NSManagedObject, Codable {
    static var currentWorkoutFetchRequest: NSFetchRequest<Workout> {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) == %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return request
    }

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    // MARK: Derived properties
    
    var isCompleted: Bool? {
        guard let workoutExercises = workoutExercises else { return nil }
        return !workoutExercises
            .compactMap { $0 as? WorkoutExercise }
            .contains { !($0.isCompleted ?? false) }
    }
    
    var hasCompletedSets: Bool? {
        guard let workoutExercises = workoutExercises else { return nil }
        return workoutExercises
            .compactMap { $0 as? WorkoutExercise }
            .contains {
                guard let sets = $0.workoutSets?.compactMap({ $0 as? WorkoutSet }) else { return false }
                return sets.contains { $0.isCompleted }
            }
    }
    
    func displayTitle(in exercises: [Exercise]) -> String {
        if let title = title {
            return title
        }
        let muscleGroups = self.muscleGroups(in: exercises)
        switch muscleGroups.count {
        case 0:
            return "Workout"
        case 1:
            return muscleGroups[0].capitalized
        default:
            return "\(muscleGroups[0].capitalized) & \(muscleGroups[1].capitalized)"
        }
    }
    
    // no duplicate entries, sorted descending by frequency
    func muscleGroups(in exercises: [Exercise]) -> [String] {
        var muscleGroups = [String]()
        
        let workoutExercises = self.workoutExercises?.array as? [WorkoutExercise] ?? []
        for workoutExercise in workoutExercises {
            if let exercise = workoutExercise.exercise(in: exercises) {
                // even if there are no sets, add the muscle group at least once
                let factor = max(workoutExercise.workoutSets?.count ?? 1, 1)
                muscleGroups.append(contentsOf: Array(repeating: exercise.muscleGroup, count: factor))
            }
        }
        return muscleGroups.sortedByFrequency().uniqed().reversed()
    }
    
    var duration: TimeInterval? {
        guard let start = start, let end = end else { return nil }
        return end.timeIntervalSince(start)
    }

    var numberOfCompletedSets: Int? {
        workoutExercises?
            .map { $0 as! WorkoutExercise }
            .reduce(0, { (count, workoutExercise) -> Int in
                count + (workoutExercise.numberOfCompletedSets ?? 0)
            })
    }
    
    var totalCompletedWeight: Double? {
        workoutExercises?
            .map { $0 as! WorkoutExercise }
            .reduce(0, { (weight, workoutExercise) -> Double in
                weight + (workoutExercise.totalCompletedWeight ?? 0)
            })
    }

    private var cancellable: AnyCancellable?
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case title
        case comment
        case start
        case end
        case exercises
    }
    
    required convenience init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Workout", in: context)
            else {
            throw CodingUserInfoKey.DecodingError.managedObjectContextMissing
        }
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        workoutExercises = NSOrderedSet(array: try container.decodeIfPresent([WorkoutExercise].self, forKey: .exercises) ?? []) // TODO: check if this is correct
        isCurrentWorkout = false // just to be sure
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(safeStart, forKey: .start)
        try container.encode(safeEnd, forKey: .end)
        try container.encodeIfPresent(workoutExercises?.array.compactMap { $0 as? WorkoutExercise }, forKey: .exercises)
    }
}

// MARK: - Safe accessors
extension Workout {
    var safeStart: Date {
        get {
            start ?? min(end ?? Date(), Date())
        }
        set {
            precondition(end == nil || newValue <= end!)
            start = newValue
        }
    }
    
    var safeEnd: Date {
        get {
            end ?? max(start ?? Date(), Date())
        }
        set {
            precondition(start == nil || newValue >= start!)
            end = newValue
        }
    }
    
    var safeDuration: TimeInterval {
        safeEnd.timeIntervalSince(safeStart)
    }
}

// MARK: - Prepare for finish
extension Workout {
    func prepareForFinish() {
        deleteExercisesWhereAllSetsAreUncompleted()
        deleteUncompletedSets()
        // should already be set, but just to be safe
        start = safeStart
        end = safeEnd
    }
    
    // exercises with no sets won't be deleted
    func deleteExercisesWhereAllSetsAreUncompleted() {
        workoutExercises?
            .compactMap { $0 as? WorkoutExercise }
            .filter {
                guard let sets = $0.workoutSets?.compactMap({ $0 as? WorkoutSet }) else { return false }
                return !sets.isEmpty && !sets.contains { $0.isCompleted }
        }
        .forEach { workoutExercise in
            managedObjectContext?.delete(workoutExercise)
            workoutExercise.workout?.removeFromWorkoutExercises(workoutExercise)
        }
    }
    
    func deleteUncompletedSets() {
        workoutExercises?
            .compactMap { $0 as? WorkoutExercise }
            .compactMap { $0.workoutSets?.compactMap { $0 as? WorkoutSet } }
            .flatMap { $0 }
            .filter { !$0.isCompleted }
            .forEach { workoutSet in
                managedObjectContext?.delete(workoutSet)
                workoutSet.workoutExercise?.removeFromWorkoutSets(workoutSet)
        }
    }
}

// MARK: - Workout Log
extension Workout {
    func logText(in exercises: [Exercise], weightUnit: WeightUnit) -> String? {
        guard let start = start else { return nil }
        guard let duration = duration else { return nil }
        guard let weight = totalCompletedWeight else { return nil }
        let dateFormatter = DateFormatter() // we don't want relative formatting here
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = "\(dateFormatter.string(from: start))"
        let durationString = "Duration: \(Self.durationFormatter.string(from: duration)!)"
        let weightString = "Total weight: \(weightUnit.format(weight: weight))"
        
        guard let workoutExercises = workoutExercisesWhereNotAllSetsAreUncompleted else { return nil }
        let exercisesDescription = workoutExercises
            .map { workoutExercise -> String in
                let exerciseTitle = (workoutExercise.exercise(in: exercises)?.title ?? "Unknown Exercise")
                guard let workoutSets = workoutExercise.workoutSets else { return exerciseTitle }
                let setsDescription = workoutSets
                    .compactMap { $0 as? WorkoutSet }
                    .filter { $0.isCompleted }
                    .map { $0.logTitle(unit: weightUnit) }
                    .joined(separator: "\n")
                guard !setsDescription.isEmpty else { return exerciseTitle }
                return exerciseTitle + "\n" + setsDescription
        }
        .joined(separator: "\n\n")
        return [dateString, durationString, weightString + "\n", exercisesDescription].joined(separator: "\n")
    }
    
    var workoutExercisesWhereNotAllSetsAreUncompleted: [WorkoutExercise]? {
        workoutExercises?
            .compactMap { $0 as? WorkoutExercise }
            .filter {
                guard let sets = $0.workoutSets?.compactMap({ $0 as? WorkoutSet }) else { return false }
                return sets.isEmpty || sets.contains { $0.isCompleted }
        }
    }
}

// MARK: - Repeat
extension Workout {
    static func copyForRepeat(workout: Workout, blank: Bool) -> Workout? {
        guard let context = workout.managedObjectContext else { return nil }
        
        // create the workout
        let newWorkout = Workout(context: context)
        
        if let workoutExercises = workout.workoutExercises?.compactMap({ $0 as? WorkoutExercise }) {
            // copy the exercises
            for workoutExercise in workoutExercises {
                let newWorkoutExercise = WorkoutExercise(context: context)
                newWorkout.addToWorkoutExercises(newWorkoutExercise)
                newWorkoutExercise.exerciseUuid = workoutExercise.exerciseUuid
                
                if let workoutSets = workoutExercise.workoutSets?.compactMap({ $0 as? WorkoutSet }) {
                    // copy the sets
                    for workoutSet in workoutSets {
                        let newWorkoutSet = WorkoutSet(context: context)
                        newWorkoutExercise.addToWorkoutSets(newWorkoutSet)
                        newWorkoutSet.isCompleted = false
                        if !blank {
                            newWorkoutSet.weight = workoutSet.weight
                            newWorkoutSet.repetitions = workoutSet.repetitions
                            // don't copy RPE, tag, comment, etc.
                        }
                    }
                }
            }
        }
        
        return newWorkout
    }
}

// MARK: - Validation
extension Workout {
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        if start == nil {
            throw error(code: 1, message: "start not set")
        }
        
        if !isCurrentWorkout, end == nil {
            throw error(code: 2, message: "end not set on finished workout")
        }
        
        if let start = start, let end = end, start > end {
            throw error(code: 3, message: "start is greater than end")
        }
        
        if isCurrentWorkout, let count = try? managedObjectContext?.count(for: Self.currentWorkoutFetchRequest), count > 1 {
            throw error(code: 4, message: "more than one current workout")
        }

        if !isCurrentWorkout, let isCompleted = isCompleted, !isCompleted {
            throw error(code: 5, message: "workout that is not current workout is uncompleted")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "WORKOUT_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}

// MARK: - Observable
extension Workout {
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
                    if let workoutExercise = managedObject as? WorkoutExercise {
                        return workoutExercise.workout?.objectID == self.objectID
                    }
                    if let workoutSet = managedObject as? WorkoutSet {
                        return workoutSet.workoutExercise?.workout?.objectID == self.objectID
                    }
                    return managedObject.objectID == self.objectID
                }
            }
            .sink { _ in self.objectWillChange.send() }
    }
}
