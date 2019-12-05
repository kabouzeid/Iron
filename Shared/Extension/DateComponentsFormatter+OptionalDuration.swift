//
//  DateComponentsFormatter+OptionalDuration.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension DateComponentsFormatter {
    func string(from ti: TimeInterval?, fallback: String?) -> String? {
        guard let ti = ti else { return fallback }
        return string(from: ti)
    }
}
