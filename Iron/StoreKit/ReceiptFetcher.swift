//
//  ReceiptFetcher.swift
//  Iron
//
//  Created by Karim Abou Zeid on 27.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import StoreKit
import os.log

enum ReceiptFetcher {
    enum FetchError: Error {
        case receiptFetch(Error)
        case noReceiptAfterFetch
    }
    
    // we need a strong references to the requests so they can complete
    private static var receiptRequests = Set<ReceiptRequest>()
    
    /// verifies with the production server first, and then with the sandbox server if necessary
    static func fetch(completion: @escaping (Result<Data, FetchError>) -> Void) {
        os_log("Fetching receipt", log: .iap, type: .default)
        if let data = fetchLocalReceipt() {
            os_log("Found local receipt", log: .iap, type: .info)
            completion(.success(data))
        } else {
            os_log("Requesting receipt from Apple", log: .iap, type: .default)
            let receiptRequest = ReceiptRequest { receiptRequest, result in
                receiptRequests.remove(receiptRequest)
                switch result {
                case .success:
                    if let data = fetchLocalReceipt() {
                        os_log("Received receipt", log: .iap, type: .info)
                        completion(.success(data))
                    } else {
                        os_log("Receipt fetch reported success, but the receipt is still missing.", log: .iap, type: .fault)
                        completion(.failure(.noReceiptAfterFetch))
                    }
                case .failure(let error):
                    os_log("Could not fetch receipt: %@", log: .iap, type: .fault, error.localizedDescription)
                    completion(.failure(.receiptFetch(error)))
                }
            }
            receiptRequests.insert(receiptRequest)
            receiptRequest.start()
        }
    }
    
    private static func fetchLocalReceipt() -> Data? {
        guard let receiptDataURL = Bundle.main.appStoreReceiptURL else { return nil }
        return try? Data(contentsOf: receiptDataURL, options: .alwaysMapped)
    }
}


private class ReceiptRequest: NSObject {
    typealias RequestCompletion = (ReceiptRequest, Result<Void, Error>) -> Void
    
    let completion: RequestCompletion
    let receiptRefreshRequest: SKReceiptRefreshRequest
    
    init(completion: @escaping RequestCompletion) {
        self.completion = completion
        self.receiptRefreshRequest = SKReceiptRefreshRequest()
        super.init()
        self.receiptRefreshRequest.delegate = self
    }
    
    func start() {
        self.receiptRefreshRequest.start()
    }
}


extension ReceiptRequest: SKRequestDelegate {
    func requestDidFinish(_ request: SKRequest) {
        completion(self, .success(()))
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        completion(self, .failure(error))
    }
}
