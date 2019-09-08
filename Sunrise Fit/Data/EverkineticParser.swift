//
//  EverkineticParser.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 08.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftyJSON

enum EverkineticParser {
    static func parse(jsonString: String) -> [Exercise] {
        JSON(parseJSON: jsonString).array?.compactMap { exerciseJson -> Exercise? in
            guard let idString = exerciseJson["id"].string, let id = Int(idString) else { assertionFailure("Exercise with malformed id found"); return nil }
            return Exercise(
                id: id,
                title: exerciseJson["title"].string ?? "",
                description: exerciseJson["primer"].string ?? "",
                type: exerciseJson["type"].string ?? "",
                primaryMuscle: exerciseJson["primary"].array?.compactMap { $0.string } ?? [],
                secondaryMuscle: exerciseJson["secondary"].array?.compactMap { $0.string } ?? [],
                equipment: exerciseJson["equipment"].array?.compactMap { $0.string } ?? [],
                steps: exerciseJson["steps"].array?.compactMap { $0.string } ?? [],
                tips: exerciseJson["tips"].array?.compactMap { $0.string } ?? [],
                references: exerciseJson["references"].array?.compactMap { $0.string } ?? [],
                png: exerciseJson["png"].array?.compactMap { $0.string } ?? []
            )
            } ?? []
    }
}
