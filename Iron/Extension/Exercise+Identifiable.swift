//
//  Exercise+Identifiable.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 21.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftUI

extension Exercise: Identifiable {
    var id: UUID { uuid }
}
