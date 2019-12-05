//
//  ArrayExtension.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 11.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    
    public func uniqed() -> [Element] {
        var arrayCopy = self
        arrayCopy.uniq()
        return arrayCopy
    }
    
    mutating public func uniq() {
        var seen = [Element]()
        var index = 0
        while self.count > index {
            let element = self[index]
            if seen.contains(element) {
                remove(at: index)
            } else {
                seen.append(element)
                index += 1
            }
        }
    }
}
