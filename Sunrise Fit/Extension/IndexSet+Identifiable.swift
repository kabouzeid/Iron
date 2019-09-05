//
//  IndexSet+Identifiable.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 05.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension IndexSet: Identifiable {
    public var id: Int { hashValue }
}
