//
//  Quote.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct Quote: Decodable {
    let text: String
    let person: String?
}

extension Quote {
    var displayText: String {
        text.enquoted + (person.map { " – \($0)" } ?? "")
    }
}
