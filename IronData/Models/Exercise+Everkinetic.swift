//
//  Exercise+Everkinetic.swift
//  IronData
//
//  Created by Karim Abou Zeid on 22.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Exercise {
    static func fromJSON(data: Data) throws -> [Exercise] {
        try JSONDecoder().decode([EverkineticExercise].self, from: data).map(\.exercise)
    }
    
    private struct EverkineticExercise: Codable {
        let uuid: UUID
        let title: String
        let alias: [String]
        let type: String
        let primary: [String]
        let secondary: [String]
        let equipment: [String]
        let pdf: [String]
        
        var aliases: String? {
            alias.joined(separator: "\n")
        }
        
        var images: ImageURLs? {
            ImageURLs(urls: pdf.map { Everkinetic.resourcesURL.appendingPathComponent($0) })
        }
        
        var movementType: MovementType? {
            switch type {
            case "compound":
                return .compound
            case "isolation":
                return .isolation
            default:
                return nil
            }
        }
        
        var bodyPart: BodyPart? {
            guard let muscle = primary.first else { return nil }
            switch muscle {
            case "abdominals", "obliques":
                return .core
            case "biceps brachii", "triceps brachii":
                return .arms
                case "deltoid":
                return .shoulders
            case "erector spinae", "latissimus dorsi", "trapezius":
                return .back
            case "gastrocnemius", "soleus", "glutaeus maximus", "ischiocrural muscles", "quadriceps":
                return .legs
            case "pectoralis major":
                return .chest
            default:
                return nil
            }
        }
        
        var category: Category {
            // TODO: this needs to be properly set in the json file for each exercise
            if equipment.contains("barbell") {
                return .barbell
            } else if equipment.contains("dumbbell") {
                return .dumbbell
            } else if equipment.contains("body") {
                return .bodyweight
            } else {
                return .machine
            }
        }
        
        var exercise: Exercise {
            Exercise(uuid: uuid, title: title, aliases: aliases, images: images, movementType: movementType, bodyPart: bodyPart, category: category)
        }
    }
}
