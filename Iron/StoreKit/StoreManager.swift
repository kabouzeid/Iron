//
//  StoreManager.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import StoreKit

class StoreManager: NSObject {
    static let shared = StoreManager()
    
    @Published private(set) var products: [SKProduct]?
    
    /// Keeps a strong reference to the product request.
    private var productRequest: SKProductsRequest!
    
    func fetchProducts(matchingIdentifiers identifiers: [String]) {
        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)

        // Initialize the product request with the above identifiers.
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self

        // Send the request to the App Store.
        productRequest.start()
    }
}

extension StoreManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async { // make sure to publish on the main thread
            self.products = response.products
        }
    }
    
    // optional
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error)
    }
}

extension SKProduct {
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

extension StoreManager: ObservableObject {}
