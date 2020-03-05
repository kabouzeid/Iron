//
//  ReceiptVerifier.swift
//  Iron
//
//  Created by Karim Abou Zeid on 25.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import StoreKit
import Combine
import os.log

enum ReceiptVerifier {
    enum VerificationError: Error {
        case httpStatus(Int)
        case payloadEncoding(Error)
        case network(Error)
        case noDataReturned
        case payloadDecoding(Error?)
        case responseStatus(VerificationResponse)
    }
    
    static func verify(receipt: Data, completion: @escaping (Result<VerificationResponse, VerificationError>) -> Void) {
        os_log("Verifiyng receipt", log: .iap, type: .default)
        
        guard let url = URL(string: "https://iron-iap-verifier.herokuapp.com/verifyReceipt") else {
            fatalError("URL is hardcoded and this should never fail")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["receipt-data" : receipt.base64EncodedString(options: [])]
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            os_log("Could not encode payload for receipt verification: %@", log: .iap, type: .error, error.localizedDescription)
            completion(.failure(.payloadEncoding(error)))
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: request) { data, urlResponse, urlError in
            if let urlResponse = urlResponse as? HTTPURLResponse {
                guard urlResponse.statusCode == 200 else {
                    os_log("HTTP response status code of the verification server was %d", log: .iap, type: .error, urlResponse.statusCode)
                    completion(.failure(.httpStatus(urlResponse.statusCode)))
                    return
                }
            }
            
            if let urlError = urlError {
                os_log("HTTP request to the verification server failed: %@", log: .iap, type: .fault, urlError.localizedDescription)
                completion(.failure(.network(urlError)))
                return
            }
            
            guard let data = data else {
                os_log("Verification server did not return any data", log: .iap, type: .error)
                completion(.failure(.noDataReturned))
                return
            }
            
            let response: VerificationResponse
            do {
                response = try JSONDecoder().decode(VerificationResponse.self, from: data)
            } catch {
                os_log("Could not decode the response of the verification server: %@", log: .iap, type: .error, error.localizedDescription)
                completion(.failure(.payloadDecoding(error)))
                return
            }
            
            os_log("Successfully got response from verification server", log: .iap, type: .info)
            
            guard response.status == 0 else {
                os_log("Verification server response status=%d", log: .iap, type: .error, response.status)
                completion(.failure(.responseStatus(response)))
                return
            }
            
            completion(.success(response))
        }
        dataTask.resume()
    }
}
