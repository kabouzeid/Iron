//
//  UserDefaults+PinnedCharts.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 03.11.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import UIKit

extension UserDefaults {
    enum PinnedChartsKeys: String {
        case pinnedChartsKey
    }
    
    var pinnedCharts: [PinnedChart] {
        get {
            guard let data = self.data(forKey: PinnedChartsKeys.pinnedChartsKey.rawValue) else { return [] }
            return (try? JSONDecoder().decode([PinnedChart].self, from: data)) ?? []
        }
        set {
            let data = try? JSONEncoder().encode(newValue.uniqed())
            self.set(data, forKey: PinnedChartsKeys.pinnedChartsKey.rawValue)
        }
    }
}
