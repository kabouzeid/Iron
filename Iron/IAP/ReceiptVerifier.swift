//
//  ReceiptVerifier.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import StoreKit
import Combine

enum ReceiptVerifier {
    private enum VerificationServers {
        static let production = "https://buy.itunes.apple.com/verifyReceipt"
        static let sandbox = "https://sandbox.itunes.apple.com/verifyReceipt"
    }
    
    private static let sharedKey = "d31cbc9ae606488c88eb6cf8528c7ad3"
    
    enum VerificationError: Error {
        case malformedServerURL
        case payloadEncoding(Error)
        case network(Error)
        case noDataReturned
        case payloadDecoding(Error?)
        case receiptInvalidStatus(Int?)
        case sandboxReceipt
    }
    
    /// verifies with the production server first, and then with the sandbox server if necessary
    static func verify(receiptData: Data, completion: @escaping (Result<VerificationResponse, VerificationError>) -> Void) {
        guard let production = URL(string: VerificationServers.production) else {
            completion(.failure(.malformedServerURL))
            return
        }
        verify(receiptData: receiptData, server: production) { result in
            switch result {
            case .success(let value):
                completion(.success(value))
            case .failure(let error):
                switch error {
                case .sandboxReceipt: // retry with sandbox server
                    print("Retry receipt validation on sandbox server")
                    guard let sandbox = URL(string: VerificationServers.sandbox) else {
                        completion(.failure(.malformedServerURL))
                        return
                    }
                    self.verify(receiptData: receiptData, server: sandbox, completion: completion)
                default:
                    completion(.failure(error))
                }
            }
        }
    }
    
    private static func verify(receiptData: Data, server: URL, completion: @escaping (Result<VerificationResponse, VerificationError>) -> Void) {
        var request = URLRequest(url: server)
        request.httpMethod = "POST"
        
        let receipt = receiptData.base64EncodedString(options: [])
        let payload = ["receipt-data" : receipt, "password" : Self.sharedKey, "exclude-old-transactions" : "true"]
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            //        print(String(data: payloadData, encoding: .utf8)!) // TODO: remove
        } catch {
            completion(.failure(.payloadEncoding(error)))
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, _, urlError in
            if let urlError = urlError {
                completion(.failure(.network(urlError)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noDataReturned))
                return
            }
            
            // decode data
            let decoded: Any
            do {
                decoded = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            } catch {
                completion(.failure(.payloadDecoding(error)))
                return
            }
            guard let responsePayload = decoded as? [String : Any] else {
                completion(.failure(.payloadDecoding(nil)))
                return
            }
            
            guard let status = responsePayload["status"] as? Int else {
                completion(.failure(.receiptInvalidStatus(nil)))
                return
            }
            
            if status == 21007 {
                completion(.failure(.sandboxReceipt))
                return
            }
            
            guard status == 0 else {
                completion(.failure(.receiptInvalidStatus(status)))
                return
            }
            
            let verificationResponse: VerificationResponse
            do {
                verificationResponse = try VerificationResponse(json: responsePayload)
            } catch {
                completion(.failure(.payloadDecoding(error)))
                return
            }
            
            completion(.success(verificationResponse))
        }
        dataTask.resume()
    }
}
