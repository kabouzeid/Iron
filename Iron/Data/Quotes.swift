//
//  QuoteProvider.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 08.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum Quotes {
    static let quotes: [Quote] = loadQuotes() ?? []

    private static func loadQuotes() -> [Quote]? {
        let jsonUrl = Bundle.main.bundleURL.appendingPathComponent("quotes").appendingPathComponent("quotes.json")
        guard let data = try? Data(contentsOf: jsonUrl) else { return nil }
        do {
            return try JSONDecoder().decode([Quote].self, from: data)
        } catch {
            print(error)
            assertionFailure()
            return nil
        }
    }
}
