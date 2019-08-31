//
//  TrainingSetTag.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum TrainingSetTag: String, CaseIterable {
//    case warmUp // disable for now, see if there is a need for this
    case dropSet
    case failure
    
    var title: String {
        switch self {
//        case .warmUp:
//            return "warm up"
        case .dropSet:
            return "drop set"
        case .failure:
            return "failure"
        }
    }
}
