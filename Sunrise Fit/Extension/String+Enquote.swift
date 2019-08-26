//
//  String+Enquote.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 26.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension String {
    var enquoted: String {
        let beginQuote = Locale.current.quotationBeginDelimiter ?? "\""
        let endQuote = Locale.current.quotationEndDelimiter ?? "\""
        return beginQuote + self + endQuote
    }
}
