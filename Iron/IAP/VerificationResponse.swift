//
//  VerificationResponse.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

struct VerificationResponse {
    let status: Int
    let latestReceiptInfo: [Receipt]
}

struct Receipt {
    /// The product identifier of the item that was purchased. This value corresponds to the productIdentifier property of the SKPayment object stored in the transaction’s payment property.
    let productIdentifier: String
    /// The transaction identifier of the item that was purchased. This value corresponds to the transaction’s transactionIdentifier property.
    let transactionIdentifier: String
    /// For a transaction that restores a previous transaction, the transaction identifier of the original transaction. Otherwise, identical to the transaction identifier. This value corresponds to the original transaction’s transactionIdentifier property. All receipts in a chain of renewals for an auto-renewable subscription have the same value for this field.
    let originalTransactionIdentifier: String
    /// The date and time that the item was purchased. This value corresponds to the transaction’s transactionDate property.
    let purchaseDate: Date
    /// For a transaction that restores a previous transaction, the date of the original transaction. This value corresponds to the original transaction’s transactionDate property. In an auto-renewable subscription receipt, this indicates the beginning of the subscription period, even if the subscription has been renewed.
    let originalPurchaseDate: Date
    /// The expiration date for the subscription, expressed as the number of milliseconds since January 1, 1970, 00:00:00 GMT. This key is only present for auto-renewable subscription receipts.
    let subscriptionExpirationDate: Date?
    /// For a transaction that was canceled by Apple customer support, the time and date of the cancellation. For an auto-renewable subscription plan that was upgraded, the time and date of the upgrade transaction. Treat a canceled receipt the same as if no purchase had ever been made.
    let cancellationDate: Date?
}

extension VerificationResponse {
    enum ParseError: Error {
        case status([String : Any])
        case latest_receipt_info([String : Any])
    }
    
    init(json: [String : Any]) throws {
        guard let status = json["status"] as? Int else { throw ParseError.status(json) }
        self.status = status
        
        guard let latest_receipt_info = json["latest_receipt_info"] as? [[String : Any]] else { throw ParseError.latest_receipt_info(json) }
        latestReceiptInfo = try latest_receipt_info.map {
            try Receipt(json: $0)
        }
        
        print("parsed \(latest_receipt_info.count) receipts in latest_receipt_info")
    }
}

extension Receipt {
    enum ParseError: Error {
        case product_id([String : Any])
        case transaction_id([String : Any])
        case original_transaction_id([String : Any])
        case purchase_date([String : Any])
        case original_purchase_date([String : Any])
        case expires_date([String : Any])
        case cancellation_date([String : Any])
    }
    
    init(json: [String : Any]) throws {
        guard let productIdentifier = json["product_id"] as? String else { throw ParseError.product_id(json) }
        self.productIdentifier = productIdentifier
        
        guard let transactionIdentifier = json["transaction_id"] as? String else { throw ParseError.transaction_id(json) }
        self.transactionIdentifier = transactionIdentifier
        
        guard let originalTransactionIdentifier = json["original_transaction_id"] as? String else { throw ParseError.original_transaction_id(json) }
        self.originalTransactionIdentifier = originalTransactionIdentifier
        
        guard let purchaseDate = Self.parseDate(string: json["purchase_date"] as? String, ms_string: json["purchase_date_ms"] as? String) else { throw ParseError.purchase_date(json) }
        self.purchaseDate = purchaseDate
        
        guard let originalPurchaseDate = Self.parseDate(string: json["original_purchase_date"] as? String, ms_string: json["original_purchase_date_ms"] as? String) else { throw ParseError.original_purchase_date(json) }
        self.originalPurchaseDate = originalPurchaseDate
        
        if let subscriptionExpirationDateString = json["expires_date"] as? String {
            guard let subscriptionExpirationDate = Self.parseDate(string: subscriptionExpirationDateString, ms_string: json["expires_date_ms"] as? String) else { throw ParseError.expires_date(json) }
            self.subscriptionExpirationDate = subscriptionExpirationDate
        } else {
            self.subscriptionExpirationDate = nil
        }
        
        if let cancellationDateString = json["cancellation_date"] as? String {
            guard let cancellationDate = Self.parseDate(string: cancellationDateString, ms_string: json["cancellation_date_ms"] as? String) else { throw ParseError.cancellation_date(json) }
            self.cancellationDate = cancellationDate
        } else {
            self.cancellationDate = nil
        }
    }
    
    private static func parseDate(string: String?, ms_string: String?) -> Date? {
        guard let dateString = string else { return nil }
        
        // Apple seems inconsisten with the date format. locally the receipt has RFC3339 dates, and the documentation says this is also what the server returns
        // in reality the server currently returns "yyyy-MM-dd HH:mm:ss VV" dates
        // to be prepared if something changes we try all date formatters
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        // Date formatter code from https://www.objc.io/issues/17-security/receipt-validation/#parsing-the-receipt
        let rfc3339dateFormatter = DateFormatter()
        rfc3339dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        rfc3339dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        rfc3339dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        if let date = rfc3339dateFormatter.date(from: dateString) {
            print("parse date as \(rfc3339dateFormatter.dateFormat ?? "RFC 3339")")
            return date
        }
        
        if let date = ISO8601DateFormatter().date(from: dateString) {
            print("parse date as ISO8601")
            return date
        }
        
        // try parsing the undocumented ms string as last resort
        guard let ms_string = ms_string else { return nil }
        if let millisecondsSince1970 = Double(ms_string) {
            print("parse date as millis")
            return Date(timeIntervalSince1970: millisecondsSince1970 / 1000)
        }

        return nil
    }
}
