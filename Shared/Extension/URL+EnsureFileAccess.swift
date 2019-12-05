//
//  URL+EnsureFileAccess.swift
//  Iron
//
//  Created by Karim Abou Zeid on 29.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

extension URL {
    enum DownloadError: Error {
        case downloadDidNotStart
        case downloadTookTooLong
    }
    
    func downloadFile(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            if let res = try? promisedItemResourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]), let status = res.ubiquitousItemDownloadingStatus {
                guard status == .current else {
                    try FileManager.default.startDownloadingUbiquitousItem(at: self)

                    // poll for 30 seconds if file has finished downloading
                    DispatchQueue.global(qos: .userInitiated).async {
                        var counter = 0
                        while !FileManager.default.fileExists(atPath: self.path) {
                            Thread.sleep(forTimeInterval: 0.5)
                            
                            let mustStop = self.startAccessingSecurityScopedResource()
                            if FileManager.default.fileExists(atPath: self.path) {
                                if mustStop { self.stopAccessingSecurityScopedResource() }
                                completion(.success(()))
                                return
                            }
                            if mustStop { self.stopAccessingSecurityScopedResource() }
                            
                            if counter > 60 {
                                completion(.failure(DownloadError.downloadTookTooLong))
                                return
                            }
                            counter = counter + 1
                        }
                        completion(.success(()))
                    }
                    return
                }
            }
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
