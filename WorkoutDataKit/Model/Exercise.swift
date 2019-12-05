//
//  Exercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

public struct Exercise: Hashable {
    public let uuid: UUID // we use this for actually identifying the exercise
    public let everkineticId: Int // this is the everkinetic exercise id or 10000 if it's a custom exercise
    public let title: String
    public let alias: [String]
    public let description: String? // primer
    public let primaryMuscle: [String] // primary
    public let secondaryMuscle: [String] // secondary
    public let equipment: [String]
    public let steps: [String]
    public let tips: [String]
    public let references: [String]
    public let pdfPaths: [String]
}

// MARK: - Muscle Names
extension Exercise {
    public var primaryMuscleCommonName: [String] {
        primaryMuscle.map { Self.commonMuscleName(for: $0) ?? $0 }.uniqed()
    }
    
    public var secondaryMuscleCommonName: [String] {
        secondaryMuscle.map { Self.commonMuscleName(for: $0) ?? $0 }.uniqed()
    }
    
    public var muscleGroup: String {
        guard let muscle = primaryMuscle.first else { return "other" }
        return Self.muscleGroup(for: muscle) ?? "other"
    }
    
    public static var muscleNames: [String] {
        commonMuscleNames.keys.map { $0 }
    }
    
    public static func commonMuscleName(for muscle: String) -> String? {
        commonMuscleNames[muscle]
    }
    
    public static func muscleGroup(for muscle: String) -> String? {
        muscleGroupNames[muscle]
    }
    
    private static var commonMuscleNames: [String : String] = [
        "abdominals": "abdominals",
        "biceps brachii": "biceps",
        "deltoid": "shoulders",
        "erector spinae": "lower back",
        "gastrocnemius": "calves",
        "soleus": "calves",
        "glutaeus maximus": "glutes",
        "ischiocrural muscles": "hamstrings",
        "latissimus dorsi": "latissimus",
        "obliques": "obliques",
        "pectoralis major": "chest",
        "quadriceps": "quadriceps",
        "trapezius": "trapezius",
        "triceps brachii": "triceps"
    ]
    
    private static var muscleGroupNames: [String : String] = [
        // abs
        "abdominals": "abdominals",
        "obliques": "abdominals",
        // arms
        "biceps brachii": "arms",
        "triceps brachii": "arms",
        // shoulders
        "deltoid": "shoulders",
        // back
        "erector spinae": "back",
        "latissimus dorsi": "back",
        "trapezius": "back",
        // legs
        "gastrocnemius": "legs",
        "soleus": "legs",
        "glutaeus maximus": "legs",
        "ischiocrural muscles": "legs",
        "quadriceps": "legs",
        // chest
        "pectoralis major": "chest"
    ]
}

// MARK: - Exercise Type
extension Exercise {
    public enum ExerciseType: CaseIterable {
        case barbell
        case dumbbell
        case other
        
        public var title: String {
            switch self {
            case .barbell:
                return "barbell based"
            case .dumbbell:
                return "dumbbell based"
            case .other:
                return "other"
            }
        }
        
        var equipment: String? {
            switch self {
            case .barbell:
                return "barbell"
            case .dumbbell:
                return "dumbbells"
            case .other:
                return nil
            }
        }
    }
    
    public var type: ExerciseType {
        ExerciseType.allCases.first { $0.equipment.map { equipment.contains($0) } ?? false } ?? .other
    }
}

// MARK: - Custom Exercise
extension Exercise {
    static let customEverkineticId = 10000
    
    private static func isCustom(everkineticId: Int) -> Bool {
        everkineticId >= Exercise.customEverkineticId
    }
    
    public var isCustom: Bool {
        Self.isCustom(everkineticId: everkineticId)
    }
}

// MARK: - Codable
extension Exercise: Codable {
    private enum CodingKeys: String, CodingKey {
        case uuid
        case id
//        case name
        case title
        case alias
        case primer
//        case type
        case primary
        case secondary
        case equipment
        case steps
        case tips
        case references
        case pdf
//        case png
    }
    
    // MARK: Decodable
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuid = try container.decode(UUID.self, forKey: .uuid)
        let id = try container.decode(Int.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let alias = try container.decodeIfPresent([String].self, forKey: .alias) ?? []
        let primer = try container.decodeIfPresent(String.self, forKey: .primer)
        let primary = try container.decode([String].self, forKey: .primary)
        let secondary = try container.decode([String].self, forKey: .secondary)
        let equipment = try container.decode([String].self, forKey: .equipment)
        let steps = try container.decodeIfPresent([String].self, forKey: .steps) ?? []
        let tips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        let references = try container.decodeIfPresent([String].self, forKey: .references) ?? []
        let pdf = try container.decodeIfPresent([String].self, forKey: .pdf) ?? []
        
        self.init(uuid: uuid, everkineticId: id, title: title, alias: alias, description: primer, primaryMuscle: primary, secondaryMuscle: secondary, equipment: equipment, steps: steps, tips: tips, references: references, pdfPaths: pdf)
    }
    
    // MARK: Encodalbe
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(everkineticId, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(alias, forKey: .alias)
        try container.encodeIfPresent(description, forKey: .primer)
        try container.encode(primaryMuscle, forKey: .primary)
        try container.encode(secondaryMuscle, forKey: .secondary)
        try container.encode(equipment, forKey: .equipment)
        try container.encode(steps, forKey: .steps)
        try container.encode(tips, forKey: .tips)
        try container.encode(references, forKey: .references)
        try container.encode(pdfPaths, forKey: .pdf)
    }
}
