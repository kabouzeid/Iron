//
//  BackupFileStore.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation

class BackupFileStore: ObservableObject {
    static let shared = BackupFileStore()
    
    private init() {}
    
    struct BackupFile: Identifiable {
        let url: URL
        let creationDate: Date
        let fileSize: Int
        
        var id: URL { url }
    }
    
    @Published var backups = [BackupFile]()
    
    func fetchBackups() {
        UbiquityContainer.backupsUrl { result in
            guard let url = try? result.get() else { return }
            guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.typeIdentifierKey, .creationDateKey, .totalFileSizeKey]) else { return }
            let backups: [BackupFile] = urls.compactMap {
                guard let resourceValues = try? $0.resourceValues(forKeys: [.typeIdentifierKey, .creationDateKey, .totalFileSizeKey]) else { return nil }
                guard let uti = resourceValues.typeIdentifier, uti == "com.kabouzeid.ironbackup" else { return nil }
                guard let creationDate = resourceValues.creationDate else { return nil }
                guard let totalFileSize = resourceValues.totalFileSize else { return nil }
                return BackupFile(url: $0, creationDate: creationDate, fileSize: totalFileSize)
            }
            DispatchQueue.main.async {
                self.backups = backups
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
                let url = try result.get()
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let fileUrl = url.appendingPathComponent(formatter.string(from: Date())).appendingPathExtension("ironbackup")
                
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
        backups.max { $0.creationDate < $1.creationDate }
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
