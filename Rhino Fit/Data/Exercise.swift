//
//  Exercise.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct Exercise {
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
    
    var primaryMuscleCommonName: [String] {
        get {
            return primaryMuscle.flatMap({ (muscle) -> String? in
                return commonName(muscle: muscle)
            })
        }
    }
    
    var secondaryMuscleCommonName: [String] {
        get {
            return secondaryMuscle.flatMap({ (muscle) -> String? in
                return commonName(muscle: muscle)
            })
        }
    }
    
    var muscleGroup: String {
        get {
            return sectionName(muscle: primaryMuscle[0])
        }
    }
    
    private func commonName(muscle: String) -> String {
        switch muscle {
        case "abdominals":
            return "Abdominals"
        case "biceps brachii":
            return "Biceps"
        case "deltoid":
            return "Shoulders"
        case "erector spinae":
            return "Lower back"
        case "gastrocnemius":
            return "Calves"
        case "glutaeus maximus":
            return "Glutes"
        case "ischiocrural muscles":
            return "Hamstrings"
        case "latissimus dorsi":
            return "Latissimus"
        case "obliques":
            return "Obliques"
        case "pectoralis major":
            return "Chest"
        case "quadriceps":
            return "Quadriceps"
        case "trapezius":
            return "Trapezius"
        case "triceps brachii":
            return "Triceps"
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
            return "Abdominal"
            
        // Arms
        case "biceps brachii":
            fallthrough
        case "triceps brachii":
            return "Arms"
            
        // Shoulders
        case "deltoid":
            return "Shoulders"
            
        // Back
        case "trapezius":
            fallthrough
        case "latissimus dorsi":
            fallthrough
        case "erector spinae":
            return "Back"
            
        // Legs
        case "ischiocrural muscles":
            fallthrough
        case "quadriceps":
            fallthrough
        case "gastrocnemius":
            return "Legs"
            
        // Glutes
        case "glutaeus maximus":
            return "Glutes"
        
        // Chest
        case "pectoralis major":
            return "Chest"
            
        // Other
        default:
            return "Other"
        }
    }
    
}
