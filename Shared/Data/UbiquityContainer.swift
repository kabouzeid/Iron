//
//  UbiquityContainer.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import os.log

enum UbiquityContainer {
    enum UbiquityContainerError: Error {
        case noUrlForContainer
    }
    
    static func containerUrl(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            os_log("Requesting url for ubiquity container", log: .ubiquityContainer, type: .default)
            guard let containerUrl = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
                os_log("Ubiquity container could not be located or iCloud storage is unavailable", log: .ubiquityContainer, type: .fault)
                completion(.failure(UbiquityContainerError.noUrlForContainer))
                return
            }
            os_log("Successfully obtained url for ubiquity container", log: .ubiquityContainer, type: .info)
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
                        os_log("Creating directory in ubiquity container: %@", log: .ubiquityContainer, type: .default, url.path)
                        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                        os_log("Successfully created directory in ubiquity container: %@", log: .ubiquityContainer, type: .info, url.path)
                    } catch {
                        os_log("Could not create directory in ubiquity container: %@", log: .ubiquityContainer, type: .fault, url.path)
                        completion(.failure(error))
                        return
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
