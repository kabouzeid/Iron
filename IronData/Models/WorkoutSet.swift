import GRDB
import Foundation

/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
public struct WorkoutSet: Identifiable, Equatable, Hashable {
    public var id: Int64?
    public var uuid: UUID = UUID()
    public var order: Int = 0 // doesn't matter
    public var weight: Double?
    public var repetitions: Int?
    public var targetRepetitionsLower: Int?
    public var targetRepetitionsUpper: Int?
    public var rpe: Double?
    public var comment: String?
    public var tag: Tag?
    public var isCompleted: Bool = false
    public let workoutExerciseId: Int64
    
    public enum Tag: Codable, CaseIterable {
        case warmup, dropset, failure
    }
}

extension WorkoutSet {
    public static let workoutExercise = belongsTo(WorkoutExercise.self)
    
    public var workoutExercise: QueryInterfaceRequest<WorkoutExercise> {
        request(for: Self.workoutExercise)
    }
}

extension WorkoutSet {
    public static func new(workoutExerciseId: Int64) -> WorkoutSet {
        WorkoutSet(workoutExerciseId: workoutExerciseId)
    }
        
    static func makeRandom(workoutExerciseId: Int64) -> WorkoutSet {
        WorkoutSet(
            uuid: UUID(),
            weight: 2.5 * Double(Int.random(in: 8...40)),
            repetitions: .random(in: 5...12),
            targetRepetitionsLower: nil,
            targetRepetitionsUpper: nil,
            rpe: Int.random(in: 0..<5) == 0 ? Double(Int.random(in: 12...20)) / 2 : nil,
            comment: randomComment(),
            tag: Int.random(in: 0..<10) == 0 ? Tag.allCases.randomElement() : nil,
            isCompleted: true,
            workoutExerciseId: workoutExerciseId
        )
    }
    
    private static func randomComment() -> String? {
        nil
    }
}

// MARK: - Persistence

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension WorkoutSet: Codable, FetchableRecord, MutablePersistableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let uuid = Column(CodingKeys.uuid)
        public static let order = Column(CodingKeys.order)
        public static let weight = Column(CodingKeys.weight)
        public static let repetitions = Column(CodingKeys.repetitions)
        public static let targetRepetitionsLower = Column(CodingKeys.targetRepetitionsLower)
        public static let targetRepetitionsUpper = Column(CodingKeys.targetRepetitionsUpper)
        public static let rpe = Column(CodingKeys.rpe)
        public static let comment = Column(CodingKeys.comment)
        public static let tag = Column(CodingKeys.tag)
        public static let isCompleted = Column(CodingKeys.isCompleted)
        public static let workoutExerciseId = Column(CodingKeys.workoutExerciseId)
    }
    
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database Requests

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest where RowDecoder == WorkoutSet {
    public func order() -> Self {
        order(WorkoutSet.Columns.order)
    }
}
