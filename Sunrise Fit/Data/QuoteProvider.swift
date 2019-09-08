//
//  QuoteProvider.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 08.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Quote {
    let text: String
    let person: String?
    
    var displayText: String {
        text.enquoted + (person.map { " – \($0)" } ?? "")
    }
}

enum QuoteProvider {
    static let quotes: [Quote] = loadQuotes() ?? []

    private static func loadQuotes() -> [Quote]? {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("quotes").appendingPathComponent("quotes.json")
        guard let jsonString = try? String(contentsOf: jsonUrl) else { return nil }
        return parse(jsonString: jsonString)
    }
    
    private static func parse(jsonString: String) -> [Quote] {
        JSON(parseJSON: jsonString).array?.compactMap { quoteJson -> Quote? in
            guard let text = quoteJson["text"].string else { return nil }
            let person = quoteJson["person"].string
            return Quote(text: text, person: person)
        } ?? []
    }
}
