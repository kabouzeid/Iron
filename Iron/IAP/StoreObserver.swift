//
//  StoreObserver.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import StoreKit

class StoreObserver: NSObject {
    static let shared = StoreObserver()
    
    override private init() {}
    
    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }
    
    func buy(product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restore() {
        print("restoring transactions...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension StoreObserver: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // first handle the transactions that we can handle immediately
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                print("purchasing: \(transaction.transactionIdentifier ?? "nil")")
            case .deferred:
                print("deferred: \(transaction.transactionIdentifier ?? "nil")")
            case .failed:
                print("failed: \(transaction.transactionIdentifier ?? "nil") with error: \(transaction.error?.localizedDescription ?? "nil")")
                queue.finishTransaction(transaction)
            case .purchased: // will handle later, this is just for debugging
                print("purchased: \(transaction.transactionIdentifier ?? "nil")")
            case .restored: // will handle later, this is just for debugging
                print("restored: \(transaction.transactionIdentifier ?? "nil")")
            @unknown default:
                break
            }
        }
        
        // if we have .purchased or .restored transactions, verify the receipt and update the entitlements
        guard transactions.contains(where: { $0.transactionState == .purchased || $0.transactionState == .restored }) else { return }
        
        ReceiptFetcher.fetch { result in
            switch result {
            case .success(let data):
                ReceiptVerifier.verify(receipt: data) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let response):
                            EntitlementStore.shared.updateEntitlements(response: response)
                            
                            for transaction in transactions {
                                // TODO: if transaction in server response mark as finished
                                // for now: just mark as finished
                                switch transaction.transactionState {
                                case .purchased:
                                    print("finish purchased \(transaction.transactionIdentifier ?? "nil")")
                                    queue.finishTransaction(transaction)
                                case .restored:
                                    print("finish restored \(transaction.transactionIdentifier ?? "nil")")
                                    queue.finishTransaction(transaction)
                                default:
                                    break
                                }
                            }
                        case .failure(let error):
                            print(error)
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("restore complete")
        NotificationCenter.default.post(name: .RestorePurchasesComplete, object: self, userInfo: [restorePurchasesSuccessUserInfoKey : true])
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("restore failed \(error)")
        NotificationCenter.default.post(name: .RestorePurchasesComplete, object: self, userInfo: [restorePurchasesSuccessUserInfoKey : false, restorePurchasesErrorUserInfoKey : error])
    }
}
