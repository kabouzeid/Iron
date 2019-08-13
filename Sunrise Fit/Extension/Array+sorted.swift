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
        let frequencies = self.frequencies(from: self)
        return self.sorted { frequencies[$0]! < frequencies[$1]! }
    }
    
    mutating public func sortByFrequency() {
        let frequencies = self.frequencies(from: self)
        self.sort { frequencies[$0]! < frequencies[$1]! }
    }
    
    private func frequencies(from array: Self) -> [Element: Int] {
        var frequencies = [Element: Int]()
        // count the frequency of each element
        for e in self {
            if frequencies[e] == nil {
                frequencies[e] = 1
            } else {
                frequencies[e] = frequencies[e]! + 1
            }
        }
        return frequencies
    }
}
