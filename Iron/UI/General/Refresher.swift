//
//  Refresher.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Combine

final class Refresher: ObservableObject {
    var objectWillChange = ObservableObjectPublisher()
    func refresh() {
        self.objectWillChange.send()
    }
}
