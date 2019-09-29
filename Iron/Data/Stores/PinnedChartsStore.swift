//
//  PinnedChartsStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 18.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine

final class PinnedChartsStore: ObservableObject {
    static let shared = PinnedChartsStore()
    
    let objectWillChange = ObservableObjectPublisher()
    
    fileprivate init() {}
    
    var pinnedCharts: [PinnedChart] {
        get {
            UserDefaults.standard.pinnedCharts
        }
        set {
            self.objectWillChange.send()
            UserDefaults.standard.pinnedCharts = newValue
        }
    }
}
