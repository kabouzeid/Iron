//
//  ReceiptFetcher.swift
//  Iron
//
//  Created by Karim Abou Zeid on 27.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import StoreKit

enum ReceiptFetcher {
    enum FetchError: Error {
        case receiptFetch(Error)
        case noReceiptAfterFetch
    }
    
    // we need a strong references to the requests so they can complete
    private static var receiptRequests = Set<ReceiptRequest>()
    
    /// verifies with the production server first, and then with the sandbox server if necessary
    static func fetch(completion: @escaping (Result<Data, FetchError>) -> Void) {
        print("fetch receipt")
        if let data = fetchLocalReceipt() {
            print("found local receipt")
            completion(.success(data))
        } else {
            print("request receipt")
            let receiptRequest = ReceiptRequest { receiptRequest, result in
                receiptRequests.remove(receiptRequest)
                print("#receiptRequests after \(receiptRequests.count)")
                switch result {
                case .success:
                    if let data = fetchLocalReceipt() {
                        print("received receipt")
                        completion(.success(data))
                    } else {
                        completion(.failure(.noReceiptAfterFetch))
                    }
                case .failure(let error):
                    completion(.failure(.receiptFetch(error)))
                }
            }
            receiptRequests.insert(receiptRequest)
            print("#receiptRequests \(receiptRequests.count)")
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
