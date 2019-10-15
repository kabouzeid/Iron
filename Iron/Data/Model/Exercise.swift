//
//  Exercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct Exercise: Hashable {
    let id: Int
    let title: String
    let alias: [String]
    let description: String? // primer
    let primaryMuscle: [String] // primary
    let secondaryMuscle: [String] // secondary
    let equipment: [String]
    let steps: [String]
    let tips: [String]
    let references: [String]
    let pdfPaths: [String]
}
 
extension Exercise {
    var primaryMuscleCommonName: [String] {
        primaryMuscle.map { Self.commonMuscleName(for: $0) ?? $0 }.uniqed()
    }
    
    var secondaryMuscleCommonName: [String] {
        secondaryMuscle.map { Self.commonMuscleName(for: $0) ?? $0 }.uniqed()
    }
    
    var muscleGroup: String {
        guard let muscle = primaryMuscle.first else { return "other" }
        return Self.muscleGroup(for: muscle) ?? "other"
    }
    
    static var muscleNames: [String] {
        commonMuscleNames.keys.map { $0 }
    }
    
    static func commonMuscleName(for muscle: String) -> String? {
        commonMuscleNames[muscle]
    }
    
    static func muscleGroup(for muscle: String) -> String? {
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

extension Exercise {
    enum ExerciseType: CaseIterable {
        case barbell
        case dumbbell
        case other
        
        var title: String {
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
    
    var type: ExerciseType {
        ExerciseType.allCases.first { $0.equipment.map { equipment.contains($0) } ?? false } ?? .other
    }
}

extension Exercise {
    static let customExerciseIdStart = 10000
    
    var isCustom: Bool {
        id >= Exercise.customExerciseIdStart
    }
}

// MARK: Codable
extension Exercise: Codable {
    private enum CodingKeys: String, CodingKey {
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
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let alias = try container.decode([String].self, forKey: .alias)
        let primer = try container.decodeIfPresent(String.self, forKey: .primer)
        let primary = try container.decode([String].self, forKey: .primary)
        let secondary = try container.decode([String].self, forKey: .secondary)
        let equipment = try container.decode([String].self, forKey: .equipment)
        let steps = try container.decode([String].self, forKey: .steps)
        let tips = try container.decode([String].self, forKey: .tips)
        let references = try container.decode([String].self, forKey: .references)
        let pdf = try container.decode([String].self, forKey: .pdf)
        
        self.init(id: id, title: title, alias: alias, description: primer, primaryMuscle: primary, secondaryMuscle: secondary, equipment: equipment, steps: steps, tips: tips, references: references, pdfPaths: pdf)
    }
    
    // MARK: Encodalbe
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
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
