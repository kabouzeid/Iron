//
//  ValueHolder.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 31.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

// when we want @State for a Binding that shouldn't trigger a view update
class ValueHolder<Value>: ObservableObject {
    var value: Value
    
    init(initial value: Value) {
        self.value = value
    }
}
