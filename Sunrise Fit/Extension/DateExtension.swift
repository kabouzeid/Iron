//
//  DateExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 08.04.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Date {
    var startOfWeek: Date? {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
    }
    
    var yesterday: Date? {
        let calendar = Calendar(identifier: .iso8601)
        return calendar.date(byAdding: .day, value: -1, to: self)
    }
}
