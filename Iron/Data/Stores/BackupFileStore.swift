//
//  BackupFileStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import UIKit

class BackupFileStore: ObservableObject {
    static let shared = BackupFileStore()
    
    private init() {}
    
    struct BackupFile: Identifiable {
        let url: URL
        let creationDate: Date
        let fileSize: Int
        let deviceName: String
        
        var id: URL { url }
    }
    
    @Published var backups = [BackupFile]()
    
    func fetchBackups() {
        UbiquityContainer.backupsUrl { result in
            guard let url = try? result.get() else { return }
            
            guard let deviceDirectoryUrls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey, .nameKey]) else { return }
            var startedDownloads = false
            let backups: [[BackupFile]] = deviceDirectoryUrls.compactMap { deviceDirectoryUrl in
                guard let resourceValues = try? deviceDirectoryUrl.resourceValues(forKeys: [.isDirectoryKey, .nameKey]) else { return nil }
                guard resourceValues.isDirectory ?? false else { return nil }
                guard let deviceName = resourceValues.name else { return nil }
                
                guard let backupUrls = try? FileManager.default.contentsOfDirectory(at: deviceDirectoryUrl, includingPropertiesForKeys: [.typeIdentifierKey, .creationDateKey, .totalFileSizeKey]) else { return nil }
                return backupUrls.compactMap { backupUrl in
                    guard let resourceValues = try? backupUrl.resourceValues(forKeys: [.typeIdentifierKey, .creationDateKey, .totalFileSizeKey]) else { return nil }
                    guard let uti = resourceValues.typeIdentifier else { return nil }
                    if uti == "com.apple.icloud-file-fault" {
                        do {
                            // if there are undownloaded files, download them and call fetchBackups() again after a short delay
                            print("starting download of iCloud file \(backupUrl)")
                            try FileManager.default.startDownloadingUbiquitousItem(at: backupUrl)
                            startedDownloads = true
                        } catch {
                            print(error)
                        }
                    }
                    guard uti == "com.kabouzeid.ironbackup" else { return nil }
                    guard let creationDate = resourceValues.creationDate else { return nil }
                    guard let totalFileSize = resourceValues.totalFileSize else { return nil }
                    return BackupFile(url: backupUrl, creationDate: creationDate, fileSize: totalFileSize, deviceName: deviceName)
                }
            }

            DispatchQueue.main.sync { // to be safe don't use async here so everything stays in order
                self.backups = backups
                    .flatMap { $0 }
                    .sorted { $0.creationDate > $1.creationDate }
            }
            
            if startedDownloads {
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(1)) {
                    print("reloading backups...")
                    self.fetchBackups()
                }
            }
        }
    }
}

// MARK: - Create / Delete Backup
extension BackupFileStore {
    func delete(at index: Int) {
        guard index < backups.count else { return }
        do { try FileManager.default.removeItem(at: backups[index].url) } catch { return }
        backups.remove(at: index)
    }
    
    func create(data: @escaping () throws -> Data, onError: @escaping (Error) -> Void) {
        Self.create(data: data) { result in
            switch result {
            case .success(_):
                self.fetchBackups()
            case .failure(let error):
                onError(error)
            }
        }
    }
    
    // data in closure so it is computed on the background thread and only if necessary
    static func create(data: @escaping () throws -> Data, completion: @escaping (Result<URL, Error>) -> Void) {
        UbiquityContainer.backupsUrl { result in
            do {
                let backupsUrl = try result.get()
                let deviceName = UIDevice.current.name
                    .components(separatedBy: CharacterSet(charactersIn: "\\/:*?\"<>|").union(.illegalCharacters))
                    .joined(separator: "")
                    .components(separatedBy: .whitespacesAndNewlines)
                    .joined(separator: " ")
                var deviceBackupUrl = backupsUrl.appendingPathComponent(deviceName)
                
                if !FileManager.default.fileExists(atPath: deviceBackupUrl.path) {
                    do {
                        try FileManager.default.createDirectory(at: deviceBackupUrl, withIntermediateDirectories: false)
                    } catch {
                        deviceBackupUrl = backupsUrl.appendingPathComponent("Unknown Device")
                        if !FileManager.default.fileExists(atPath: deviceBackupUrl.path) {
                            try FileManager.default.createDirectory(at: deviceBackupUrl, withIntermediateDirectories: false)
                        }
                    }
                }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let fileUrl = deviceBackupUrl.appendingPathComponent(formatter.string(from: Date())).appendingPathExtension("ironbackup")
                
                try data().write(to: fileUrl, options: .atomic)
                
                completion(.success(fileUrl))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Misc
extension BackupFileStore {
    var lastBackup: BackupFile? {
        backups.first // assume backups are sorted
    }
}

// MARK: - Formatters
extension BackupFileStore.BackupFile {
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    static let byteCountFormatter: ByteCountFormatter = {
        ByteCountFormatter()
    }()
}
