//
//  EverkineticParser.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 15.01.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftyJSON

class EverkineticParser {
    
    static func parse(jsonString: String) -> [Exercise] {
        let json = JSON(parseJSON: jsonString)
        var exercises: [Exercise] = []
        
        for i in 0 ..< json.count {
            let exerciseJson = json[i]
            
            let id = Int(exerciseJson["id"].string!)!
            let title = exerciseJson["title"].string!
            let description = exerciseJson["primer"].string!
            let type = exerciseJson["type"].string!
            let primaryMuscle = exerciseJson["primary"].arrayValue.map { $0.string! }
            let secondaryMuscle = exerciseJson["secondary"].arrayValue.map { $0.string! }
            let equipment = exerciseJson["equipment"].arrayValue.map { $0.string! }
            let steps = exerciseJson["steps"].arrayValue.map { $0.string! }
            let tips = exerciseJson["tips"].arrayValue.map { $0.string! }
            let references = exerciseJson["references"].arrayValue.map { $0.string! }
            let png = exerciseJson["png"].arrayValue.map { $0.string! }
            
            let exercise = Exercise(id: id, title: title, description: description, type: type, primaryMuscle: primaryMuscle, secondaryMuscle: secondaryMuscle, equipment: equipment, steps: steps, tips: tips, references: references, png: png)
            
            exercises.append(exercise)
        }
        
        return exercises
    }
    
}
