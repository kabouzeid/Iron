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
    enum VerificationError: Error {
        case httpStatus(Int)
        case malformedServerURL
        case payloadEncoding(Error)
        case network(Error)
        case noDataReturned
        case payloadDecoding(Error?)
        case responseStatus(VerificationResponse)
    }
    
    static func verify(receipt: Data, completion: @escaping (Result<VerificationResponse, VerificationError>) -> Void) {
        guard let url = URL(string: "https://iron-iap-verifier.herokuapp.com/verifyReceipt") else {
            assertionFailure("URL is hardcoded and this should never fail");
            completion(.failure(.malformedServerURL));
            return
        }
        
        print("verifiyng receipt...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["receipt-data" : receipt.base64EncodedString(options: [])]
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(.payloadEncoding(error)))
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, urlError in
            if let urlResponse = urlResponse as? HTTPURLResponse {
                guard urlResponse.statusCode == 200 else {
                    completion(.failure(.httpStatus(urlResponse.statusCode)))
                    return
                }
            }
            
            if let urlError = urlError {
                completion(.failure(.network(urlError)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noDataReturned))
                return
            }
            
            let response: VerificationResponse
            do {
                response = try JSONDecoder().decode(VerificationResponse.self, from: data)
            } catch {
                completion(.failure(.payloadDecoding(error)))
                return
            }
            
            guard response.status == 0 else {
                completion(.failure(.responseStatus(response)))
                return
            }
            
            completion(.success(response))
        }
        dataTask.resume()
    }
}
