//
//  WidgetKind.swift
//  Iron
//
//  Created by Karim Abou Zeid on 12.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import WidgetKit
import os.log

enum WidgetKind: String {
    case lastWorkout
}

@available(iOS 14.0, *)
extension WidgetKind {
    func reloadTimelines() {
        os_log("Reload timeline", log: .widgets, type: .debug)
        WidgetCenter.shared.reloadTimelines(ofKind: rawValue)
    }
}
