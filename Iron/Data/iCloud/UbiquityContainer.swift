//
//  UbiquityContainer.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

enum UbiquityContainer {
    enum UbiquityContainerError: Error {
        case noUrlForContainer
    }
    
    static func containerUrl(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                completion(.failure(UbiquityContainerError.noUrlForContainer))
                return
            }
            completion(.success(containerUrl))
        }
    }
}

extension UbiquityContainer {
    private static func containerUrl(transform: @escaping (URL) -> URL, completion: @escaping (Result<URL, Error>) -> Void) {
        containerUrl { result in
            do {
                let url = transform(try result.get())
                if !FileManager.default.fileExists(atPath: url.path) {
                    do {
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    static func documentsUrl(completion: @escaping (Result<URL, Error>) -> Void) {
        containerUrl(transform: { $0.appendingPathComponent("Documents") }, completion: completion)
    }
    
    static func backupsUrl(completion: @escaping (Result<URL, Error>) -> Void) {
        containerUrl(transform: { $0.appendingPathComponent("Documents").appendingPathComponent("Backups") }, completion: completion)
    }
}
