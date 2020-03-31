//
//  StoreObserver.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import StoreKit
import Combine
import os.log

class StoreObserver: NSObject, ObservableObject {
    static let shared = StoreObserver()
    
    let objectWillChange = ObservableObjectPublisher()
    
    override private init() {}
    
    /// Should be called at application launch
    func addToPaymentQueue() {
        SKPaymentQueue.default().add(self)
    }
    
    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    func buy(product: SKProduct) {
        SKPaymentQueue.default().add(.init(product: product))
    }
    
    func restore() {
        os_log("Restoring completed transactions", log: .iap, type: .default)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    var pendingTransactions: [SKPaymentTransaction] {
        SKPaymentQueue.default().transactions
    }
    
    /// Set when a .failed transaction appears
    var error: Error?
}

extension StoreObserver: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        objectWillChange.send()
        
        // first handle the transactions that we can handle immediately
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                os_log("Transaction in payment queue: (purchasing) %@", log: .iap, type: .info, transaction.transactionIdentifier ?? "nil")
            case .deferred:
                os_log("Transaction in payment queue: (deferred) %@", log: .iap, type: .info, transaction.transactionIdentifier ?? "nil")
            case .failed:
                os_log("Transaction in payment queue: (failed) %@ (%@)", log: .iap, type: .info, transaction.transactionIdentifier ?? "nil", transaction.error?.localizedDescription ?? "nil")
                error = transaction.error
                queue.finishTransaction(transaction)
            case .purchased: // will handle later, this is just for debugging
                os_log("Transaction in payment queue: (purchased) %@", log: .iap, type: .info, transaction.transactionIdentifier ?? "nil")
            case .restored: // will handle later, this is just for debugging
                os_log("Transaction in payment queue: (restored) %@", log: .iap, type: .info, transaction.transactionIdentifier ?? "nil")
            @unknown default:
                break
            }
        }
        
        // if we have .purchased or .restored transactions, verify the receipt and update the entitlements
        guard transactions.contains(where: { $0.transactionState == .purchased || $0.transactionState == .restored }) else { return }
        
        ReceiptFetcher.fetch { result in
            if let data = try? result.get() {
                ReceiptVerifier.verify(receipt: data) { result in
                    DispatchQueue.main.async {
                        if let response = try? result.get() {
                            EntitlementStore.shared.updateEntitlements(response: response)
                            
                            for transaction in transactions {
                                // TODO: if transaction in server response mark as finished
                                // for now: just mark as finished
                                switch transaction.transactionState {
                                case .purchased:
                                    os_log("Finish purchased transaction: %@", transaction.transactionIdentifier ?? "nil")
                                    queue.finishTransaction(transaction)
                                case .restored:
                                    os_log("Finish restored transaction: %@", transaction.transactionIdentifier ?? "nil")
                                    queue.finishTransaction(transaction)
                                default:
                                    break
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        objectWillChange.send()
    }
    
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        objectWillChange.send()
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        os_log("Successfully restored completed transactions", log: .iap, type: .info)
        NotificationCenter.default.post(name: .RestorePurchasesComplete, object: self, userInfo: [restorePurchasesSuccessUserInfoKey : true])
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        os_log("Could not restore completed transactions: %@", log: .iap, type: .fault, error.localizedDescription)
        NotificationCenter.default.post(name: .RestorePurchasesComplete, object: self, userInfo: [restorePurchasesSuccessUserInfoKey : false, restorePurchasesErrorUserInfoKey : error])
    }
}

// Keep this separate for cleaner code because of the entitlements store dependency
extension StoreObserver {
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        // If the user already bought this product or, if he has Iron Pro Lifetime, don't continue with the request.
        let entitlements = EntitlementStore.shared.entitlements
        guard !entitlements.contains(product.productIdentifier) && !entitlements.contains(IAPIdentifiers.proLifetime) else { return false }
        return true
    }
}
