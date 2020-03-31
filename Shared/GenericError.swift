//
//  GenericError.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct GenericError: Error {
    private let _description: String
    
    init(description: String) {
        _description = description
    }
}

extension GenericError: LocalizedError {
    var errorDescription: String? {
        _description
    }
}
