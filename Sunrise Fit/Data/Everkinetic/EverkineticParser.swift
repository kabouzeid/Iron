//
//  EverkineticParser.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftyJSON

struct EverkineticParser {
    static func parse(jsonString: String) -> [Exercise] {
        let json = JSON(parseJSON: jsonString)
        var exercises = [Exercise]()
        
        for i in 0 ..< json.count {
            let exerciseJson = json[i]

            let id = Int(exerciseJson["id"].stringValue)!
            let title = exerciseJson["title"].stringValue
            let description = exerciseJson["primer"].stringValue
            let type = exerciseJson["type"].stringValue
            let primaryMuscle = exerciseJson["primary"].arrayValue.map { $0.stringValue }
            let secondaryMuscle = exerciseJson["secondary"].arrayValue.map { $0.stringValue }
            let equipment = exerciseJson["equipment"].arrayValue.map { $0.stringValue }
            let steps = exerciseJson["steps"].arrayValue.map { $0.stringValue }
            let tips = exerciseJson["tips"].arrayValue.map { $0.stringValue }
            let references = exerciseJson["references"].arrayValue.map { $0.stringValue }
            let png = exerciseJson["png"].arrayValue.map { $0.stringValue }
            
            let exercise = Exercise(id: id, title: title, description: description, type: type, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, equipment: equipment, steps: steps, tips: tips, references: references, png: png)
            exercises.append(exercise)
        }
        
        return exercises
    }
}
