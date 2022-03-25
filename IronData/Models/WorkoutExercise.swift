import GRDB
import Foundation

/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
public struct WorkoutExercise: Identifiable, Equatable {
    public var id: Int64?
    public var uuid: UUID = UUID()
    public var order: Int = 0 // doesn't matter
    public var comment: String?
    public var exerciseId: Int64
    public var workoutId: Int64
}

extension WorkoutExercise {
    static let exercise = belongsTo(Exercise.self)
    static let workout = belongsTo(Workout.self)
    static let workoutSets = hasMany(WorkoutSet.self).order(WorkoutSet.Columns.order)
    
    var exercise: QueryInterfaceRequest<Exercise> {
        request(for: Self.exercise)
    }
    
    var workout: QueryInterfaceRequest<Workout> {
        request(for: Self.workout)
    }
    
    var workoutSets: QueryInterfaceRequest<WorkoutSet> {
        request(for: Self.workoutSets).order()
    }
}

extension WorkoutExercise {
    public static func new(exerciseId: Int64, workoutId: Int64) -> WorkoutExercise {
        WorkoutExercise(exerciseId: exerciseId, workoutId: workoutId)
    }
    
    static func makeRandom(exerciseId: Int64, workoutId: Int64) -> WorkoutExercise {
        WorkoutExercise(comment: randomComment(), exerciseId: exerciseId, workoutId: workoutId)
    }

    private static func randomComment() -> String? {
        nil
    }
}

// MARK: - Persistence

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension WorkoutExercise: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let uuid = Column(CodingKeys.uuid)
        static let order = Column(CodingKeys.order)
        static let comment = Column(CodingKeys.comment)
        static let exerciseId = Column(CodingKeys.exerciseId)
        static let workoutId = Column(CodingKeys.workoutId)
    }

    public mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database Requests

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest where RowDecoder == WorkoutExercise {
    func order() -> Self {
        order(WorkoutExercise.Columns.order)
    }
}
