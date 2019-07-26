//
//  HashableArrayExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 03.03.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Array where Element : Hashable {
    public func sortedByFrequency() -> [Element] {
        var arrayCopy = self
        arrayCopy.sortByFrequency()
        return arrayCopy
    }
    
    mutating public func sortByFrequency() {
        var frequencies = [Element: Int]()
        
        // count the frequency of each element
        for e in self {
            if frequencies[e] == nil {
                frequencies[e] = 1
            } else {
                frequencies[e] = frequencies[e]! + 1
            }
        }

        self = frequencies.sorted { $0.value > $1.value }.map { $0.key }
    }
}
