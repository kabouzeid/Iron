import GRDB
import Foundation

/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
struct Workout: Identifiable, Equatable {
    var id: Int64?
    var uuid: UUID = UUID()
    var start: Date
    var end: Date?
    var title: String?
    var comment: String?
    var isActive: Bool = false
}

extension Workout {
    static let workoutExercises = hasMany(WorkoutExercise.self).order(WorkoutExercise.Columns.order)
    
    var workoutExercises: QueryInterfaceRequest<WorkoutExercise> {
        request(for: Self.workoutExercises).ordered()
    }
}

extension Workout {
    static func makeRandom() -> Workout {
        Workout(start: Date(timeIntervalSinceNow: -60*60*1.5), end: Date(timeIntervalSinceNow: -60*60*0.2), title: randomTitle(), comment: randomComment(), isActive: false)
    }
    
    private static func randomTitle() -> String {
        ["Upper Body", "Lower Body", "Push", "Pull", "Legs"].randomElement()!
    }
    
    private static func randomComment() -> String? {
        nil
    }
}

// MARK: - Persistence

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension Workout: Codable, FetchableRecord, MutablePersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let uuid = Column(CodingKeys.uuid)
        static let start = Column(CodingKeys.start)
        static let end = Column(CodingKeys.end)
        static let title = Column(CodingKeys.title)
        static let comment = Column(CodingKeys.comment)
        static let isActive = Column(CodingKeys.isActive)
    }
    
    mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database Requests

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest where RowDecoder == Workout {
    func orderedByStart() -> Self {
        order(Workout.Columns.start.desc)
    }
}
