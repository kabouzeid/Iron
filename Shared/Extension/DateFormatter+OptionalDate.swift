//
//  DateFormatter+OptionalDate.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 13.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension DateFormatter {
    func string(from date: Date?, fallback: String) -> String {
        guard let date = date else { return fallback }
        return string(from: date)
    }
}
