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
    let description: String // primer
    let type: String
    let primaryMuscle: [String] // primary
    let secondaryMuscle: [String] // secondary
    let equipment: [String]
    let steps: [String]
    let tips: [String]
    let references: [String]
    let png: [String]
}
 
extension Exercise {
    var isBarbellBased: Bool {
        equipment.contains("barbell")
    }
    
    var primaryMuscleCommonName: [String] {
        primaryMuscle.map { Exercise.commonName(muscle: $0) }.uniqed()
    }
    
    var secondaryMuscleCommonName: [String] {
        secondaryMuscle.map { Exercise.commonName(muscle: $0) }.uniqed()
    }
    
    var muscleGroup: String {
        sectionName(muscle: primaryMuscle[0])
    }
    
    static func commonName(muscle: String) -> String {
        switch muscle {
        case "abdominals":
            return "abdominals"
        case "biceps brachii":
            return "biceps"
        case "deltoid":
            return "shoulders"
        case "erector spinae":
            return "lower back"
        case "gastrocnemius":
            fallthrough
        case "soleus":
            return "calves"
        case "glutaeus maximus":
            return "glutes"
        case "ischiocrural muscles":
            return "hamstrings"
        case "latissimus dorsi":
            return "latissimus"
        case "obliques":
            return "obliques"
        case "pectoralis major":
            return "chest"
        case "quadriceps":
            return "quadriceps"
        case "trapezius":
            return "trapezius"
        case "triceps brachii":
            return "triceps"
        default:
            return muscle
        }
    }
    
    private func sectionName(muscle: String) -> String {
        switch muscle {
            
        // Abdominal
        case "abdominals":
            fallthrough
        case "obliques":
            return "abdominals"
            
        // Arms
        case "biceps brachii":
            fallthrough
        case "triceps brachii":
            return "arms"
            
        // Shoulders
        case "deltoid":
            return "shoulders"
            
        // Back
        case "trapezius":
            fallthrough
        case "latissimus dorsi":
            fallthrough
        case "erector spinae":
            return "back"
            
        // Legs
        case "glutaeus maximus":
            fallthrough
        case "ischiocrural muscles":
            fallthrough
        case "quadriceps":
            fallthrough
        case "gastrocnemius":
            return "legs"
            
        // Chest
        case "pectoralis major":
            return "chest"
            
        // Other
        default:
            return "other"
        }
    }
}

extension Exercise {
    static var empty: Exercise = {
        Exercise(id: 0, title: "", description: "", type: "", primaryMuscle: [], secondaryMuscle: [], equipment: [], steps: [], tips: [], references: [], png: [])
    }()
}
