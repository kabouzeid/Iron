//
//  Workout.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine
import os.log

public class Workout: NSManagedObject, Codable {
    public static var currentWorkoutFetchRequest: NSFetchRequest<Workout> {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) == %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return request
    }

    public static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    public static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    public class func create(context: NSManagedObjectContext) -> Workout {
        let workout = Workout(context: context)
        workout.uuid = UUID()
        return workout
    }
    
    // MARK: Derived properties
    
    public var isCompleted: Bool? {
        guard let workoutExercises = workoutExercises else { return nil }
        return !workoutExercises
            .compactMap { $0 as? WorkoutExercise }
            .contains { !($0.isCompleted ?? false) }
    }
    
    public var hasCompletedSets: Bool? {
        guard let workoutExercises = workoutExercises else { return nil }
        return workoutExercises
            .compactMap { $0 as? WorkoutExercise }
            .contains {
                guard let sets = $0.workoutSets?.compactMap({ $0 as? WorkoutSet }) else { return false }
                return sets.contains { $0.isCompleted }
            }
    }

    public func workoutPlanAndRoutineTitle() -> String? {
        if let workoutRoutineTitle = workoutRoutine?.displayTitle, let workoutPlanTitle = workoutRoutine?.workoutPlan?.displayTitle {
            return workoutPlanTitle + " - " + workoutRoutineTitle
        }
        return nil
    }
    
    public func generatedTitle(in exercises: [Exercise]) -> String? {
        let muscleGroups = self.muscleGroups(in: exercises)
        switch muscleGroups.count {
        case 1:
            return muscleGroups[0].capitalized
        case 2...:
            return "\(muscleGroups[0].capitalized) & \(muscleGroups[1].capitalized)"
        default:
            return nil
        }
    }

    public func optionalDisplayTitle(in exercises: [Exercise]) -> String? {
        title ?? workoutPlanAndRoutineTitle() ?? generatedTitle(in: exercises)
    }

    public func displayTitle(in exercises: [Exercise]) -> String {
        optionalDisplayTitle(in: exercises) ?? "Workout"
    }

    // no duplicate entries, sorted descending by frequency
    public func muscleGroups(in exercises: [Exercise]) -> [String] {
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
    
    public var duration: TimeInterval? {
        guard let start = start, let end = end else { return nil }
        return end.timeIntervalSince(start)
    }

    public var numberOfCompletedSets: Int? {
        workoutExercises?
            .map { $0 as! WorkoutExercise }
            .reduce(0, { (count, workoutExercise) -> Int in
                count + (workoutExercise.numberOfCompletedSets ?? 0)
            })
    }
    
    public var totalCompletedWeight: Double? {
        workoutExercises?
            .map { $0 as! WorkoutExercise }
            .reduce(0, { (weight, workoutExercise) -> Double in
                weight + (workoutExercise.totalCompletedWeight ?? 0)
            })
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case uuid
        case title
        case comment
        case start
        case end
        case exercises
        case routineUuid
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let contextKey = CodingUserInfoKey.managedObjectContextKey,
            let context = decoder.userInfo[contextKey] as? NSManagedObjectContext,
            let entity = NSEntityDescription.entity(forEntityName: "Workout", in: context)
            else {
            throw CodingUserInfoKey.DecodingError.managedObjectContextMissing
        }
        self.init(entity: entity, insertInto: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID() // make sure we always have an UUID
        title = try container.decodeIfPresent(String.self, forKey: .title)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        start = try container.decode(Date.self, forKey: .start)
        end = try container.decode(Date.self, forKey: .end)
        workoutExercises = NSOrderedSet(array: try container.decodeIfPresent([WorkoutExercise].self, forKey: .exercises) ?? [])
        
        if let routineUuid = try container.decodeIfPresent(UUID.self, forKey: .routineUuid) {
            let request: NSFetchRequest<WorkoutRoutine> = WorkoutRoutine.fetchRequest()
            request.predicate = NSPredicate(format: "\(#keyPath(WorkoutRoutine.uuid)) == %@", routineUuid as NSUUID)
            workoutRoutine = try managedObjectContext?.fetch(request).first
            if workoutRoutine == nil {
                os_log("Could not find workout routine with uuid=%@", log: .modelCoding, type: .fault, routineUuid as NSUUID)
                throw DecodingError.dataCorruptedError(forKey: .routineUuid, in: container, debugDescription: "Could not find workout routine with uuid=\(routineUuid)")
            }
        }
        
        isCurrentWorkout = false // just to be sure
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid ?? UUID(), forKey: .uuid)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encode(safeStart, forKey: .start)
        try container.encode(safeEnd, forKey: .end)
        try container.encodeIfPresent(workoutExercises?.array.compactMap { $0 as? WorkoutExercise }, forKey: .exercises)
        try container.encodeIfPresent(workoutRoutine?.uuid, forKey: .routineUuid)
    }
}

// MARK: - Safe accessors
extension Workout {
    public var safeStart: Date {
        get {
            start ?? min(end ?? Date(), Date())
        }
        set {
            precondition(end == nil || newValue <= end!)
            start = newValue
        }
    }
    
    public var safeEnd: Date {
        get {
            end ?? max(start ?? Date(), Date())
        }
        set {
            precondition(start == nil || newValue >= start!)
            end = newValue
        }
    }
    
    public var safeDuration: TimeInterval {
        safeEnd.timeIntervalSince(safeStart)
    }
}

// MARK: - Prepare for finish
extension Workout {
    // exercises with no sets won't be deleted
    public func deleteExercisesWhereAllSetsAreUncompleted() {
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
    
    public func deleteUncompletedSets() {
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
    public func logText(in exercises: [Exercise], unit: UnitMass, formatter: MeasurementFormatter) -> String? {
        guard let start = start else { return nil }
        guard let duration = duration else { return nil }
        guard let weight = totalCompletedWeight else { return nil }
        let dateFormatter = DateFormatter() // we don't want relative formatting here
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = "\(dateFormatter.string(from: start))"
        let durationString = "Duration: \(Self.durationFormatter.string(from: duration)!)"
        let weightString = "Total weight: \(formatter.string(from: Measurement(value: weight, unit: UnitMass.kilograms).converted(to: unit)))"
        
        guard let workoutExercises = workoutExercisesWhereNotAllSetsAreUncompleted else { return nil }
        let exercisesDescription = workoutExercises
            .map { workoutExercise -> String in
                let exerciseTitle = (workoutExercise.exercise(in: exercises)?.title ?? "Unknown Exercise")
                guard let workoutSets = workoutExercise.workoutSets else { return exerciseTitle }
                let setsDescription = workoutSets
                    .compactMap { $0 as? WorkoutSet }
                    .filter { $0.isCompleted }
                    .map { $0.logTitle(unit: unit, formatter: formatter) }
                    .joined(separator: "\n")
                guard !setsDescription.isEmpty else { return exerciseTitle }
                return exerciseTitle + "\n" + setsDescription
        }
        .joined(separator: "\n\n")
        return [dateString, durationString, weightString + "\n", exercisesDescription].joined(separator: "\n")
    }
    
    public var workoutExercisesWhereNotAllSetsAreUncompleted: [WorkoutExercise]? {
        workoutExercises?
            .compactMap { $0 as? WorkoutExercise }
            .filter {
                guard let sets = $0.workoutSets?.compactMap({ $0 as? WorkoutSet }) else { return false }
                return sets.isEmpty || sets.contains { $0.isCompleted }
        }
    }
}

// MARK: - Validation
extension Workout {
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    /// TODO Subclasses should combine any error returned by super’s implementation with their own (see Managed Object Validation).
    /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/ObjectValidation.html
    func validateConsistency() throws {
        if start == nil {
            throw error(code: 1, message: "The start date is not set.")
        }
        
        if !isCurrentWorkout, end == nil {
            throw error(code: 2, message: "The end date is not set eventhough the workout is not the current workout.")
        }
        
        if let start = start, let end = end, start > end {
            throw error(code: 3, message: "The start date is greater than the end date.")
        }
        
        if isCurrentWorkout, let count = try? managedObjectContext?.count(for: Self.currentWorkoutFetchRequest), count > 1 {
            throw error(code: 4, message: "There is more than one current workout.")
        }

        if !isCurrentWorkout, let isCompleted = isCompleted, !isCompleted {
            throw error(code: 5, message: "The workout is not completed eventhough the workout is not the current workout.")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "WORKOUT_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}
