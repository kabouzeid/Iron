import GRDB
import Foundation

/// Identifiable conformance supports SwiftUI list animations, and type-safe
/// GRDB primary key methods.
/// Equatable conformance supports tests.
public struct Exercise: Identifiable, Equatable {
    public var id: Int64?
    public var uuid: UUID = UUID()
    public var title: String
    public var aliases: String?
    public var images: ImageURLs?
    public var movementType: MovementType?
    public var bodyPart: BodyPart?
    public var category: Category
    
    public enum MovementType: Codable, CaseIterable {
        case compound
        case isolation
    }
    
    public enum BodyPart: Codable, CaseIterable {
        case chest, back, legs, arms, shoulders, core
    }
    
    public enum Category: Codable, CaseIterable {
        case barbell, dumbbell, machine, bodyweight, cardio, duration
    }
    
    public struct ImageURLs: Codable, Equatable {
        public let urls: [URL]
    }
}

extension Exercise {
    public static let workoutExercises = hasMany(WorkoutExercise.self)
    
    public var workoutExercises: QueryInterfaceRequest<WorkoutExercise> {
        request(for: Self.workoutExercises)
    }
}

extension Exercise {
    public static func new(title: String, category: Category) -> Exercise {
        Exercise(title: title, category: category)
    }
        
    static func makeRandom() -> Exercise {
        Exercise.init(title: randomTitle(), aliases: nil, images: nil, movementType: MovementType.allCases.randomElement(), bodyPart: BodyPart.allCases.randomElement(), category: Category.allCases.randomElement()!)
    }
    
    private static func randomTitle() -> String {
        ["Bench Press: Barbell", "Squat: Barbell", "Triceps Pushdown"].randomElement()!
    }
}

// MARK: - Persistence

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#records>
extension Exercise: Codable, FetchableRecord, MutablePersistableRecord {
    public enum Columns {
        public static let uuid = Column(CodingKeys.uuid)
        public static let title = Column(CodingKeys.title)
        public static let aliases = Column(CodingKeys.aliases)
        public static let images = Column(CodingKeys.images)
        public static let movementType = Column(CodingKeys.movementType)
        public static let bodyPart = Column(CodingKeys.bodyPart)
        public static let category = Column(CodingKeys.category)
    }
    
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        id = rowID
    }
}

// MARK: - Database Requests

/// See <https://github.com/groue/GRDB.swift/blob/master/README.md#requests>
/// See <https://github.com/groue/GRDB.swift/blob/master/Documentation/GoodPracticesForDesigningRecordTypes.md>
extension DerivableRequest where RowDecoder == Exercise {
    public func orderByTitle() -> Self {
        order(Exercise.Columns.title.collating(.localizedCaseInsensitiveCompare))
    }
}
