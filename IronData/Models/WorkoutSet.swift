import GRDB
import Foundation

/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
struct WorkoutSet: Identifiable, Equatable {
    var id: Int64?
    var uuid: UUID = UUID()
    var order: Int = 0 // doesn't matter
    var weight: Double?
    var repetitions: Int?
    var targetRepetitionsLower: Int?
    var targetRepetitionsUpper: Int?
    var rpe: Double?
    var comment: String?
    var tag: Tag?
    var isCompleted: Bool = false
    let workoutExerciseId: Int64
    
    enum Tag: Codable, CaseIterable {
        case warmup, dropset, failure
    }
}

extension WorkoutSet {
    static let workoutExercise = belongsTo(WorkoutExercise.self)
    
    var workoutExercise: QueryInterfaceRequest<WorkoutExercise> {
        request(for: Self.workoutExercise)
    }
}

extension WorkoutSet {
    static func makeRandom(workoutExerciseId: Int64) -> WorkoutSet {
        WorkoutSet(uuid: UUID(), weight: 2.5 * Double(Int.random(in: 8...40)), repetitions: .random(in: 5...12), targetRepetitionsLower: nil, targetRepetitionsUpper: nil, rpe: Double(Int.random(in: 12...20)) / 2, comment: randomComment(), tag: Tag.allCases.randomElement(), isCompleted: true, workoutExerciseId: workoutExerciseId)
    }
    
    private static func randomComment() -> String? {
        nil
    }
}

// MARK: - Persistence

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension WorkoutSet: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let uuid = Column(CodingKeys.uuid)
        static let order = Column(CodingKeys.order)
        static let weight = Column(CodingKeys.weight)
        static let repetitions = Column(CodingKeys.repetitions)
        static let targetRepetitionsLower = Column(CodingKeys.targetRepetitionsLower)
        static let targetRepetitionsUpper = Column(CodingKeys.targetRepetitionsUpper)
        static let rpe = Column(CodingKeys.rpe)
        static let comment = Column(CodingKeys.comment)
        static let tag = Column(CodingKeys.tag)
        static let isCompleted = Column(CodingKeys.isCompleted)
        static let workoutExerciseId = Column(CodingKeys.workoutExerciseId)
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database Requests

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest where RowDecoder == WorkoutSet {
    func ordered() -> Self {
        order(WorkoutSet.Columns.order)
    }
}
