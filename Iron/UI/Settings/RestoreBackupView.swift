//
//  RestoreBackupView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 28.10.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct RestoreBackupView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @ObservedObject var backupStore: BackupFileStore
    
    @State private var restoreResult: IdentifiableHolder<Result<Void, Error>>?
    @State private var restoreBackupUrl: IdentifiableHolder<URL>?
    
    var body: some View {
        List {
            Section(header: Text("Backups".uppercased()), footer: Text("Restore a backup by tapping on it.")) {
                ForEach(backupStore.backups) { backup in
                    Button(action: {
                        self.restoreBackupUrl = IdentifiableHolder(value: backup.url)
                    }) {
                        VStack(alignment: .leading) {
                            Text(BackupFileStore.BackupFile.dateFormatter.string(from: backup.creationDate))
                                .foregroundColor(.primary)
                            Text("\(backup.deviceName) • \(BackupFileStore.BackupFile.byteCountFormatter.string(fromByteCount: Int64(backup.fileSize)))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        self.backupStore.delete(at: index)
                    }
                }
                
                // TODO: remove this once the .placeholder() works
                if backupStore.backups.isEmpty {
                    Button("Empty") {}
                        .disabled(true)
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .onAppear(perform: backupStore.fetchBackups)
        .navigationBarItems(trailing: EditButton())
        .actionSheet(item: $restoreBackupUrl) { urlHolder in
            RestoreActionSheet.create(context: self.managedObjectContext, exerciseStore: self.exerciseStore, data: { try Data(contentsOf: urlHolder.value) }) { result in
                self.restoreResult = IdentifiableHolder(value: result)
            }
        }
        .alert(item: $restoreResult) { restoreResultHolder in
            RestoreActionSheet.restoreResultAlert(restoreResult: restoreResultHolder.value)
        }
        .navigationBarTitle("Restore Backup", displayMode: .inline)
    }
}

import CoreData
enum RestoreActionSheet {
    typealias RestoreResult = Result<Void, Error>
    
    static func create(context: NSManagedObjectContext, exerciseStore: ExerciseStore, data: @escaping () throws -> Data, completion: @escaping (RestoreResult) -> Void) -> ActionSheet {
        ActionSheet(
            title: Text("Restore Backup"),
            message: Text("This cannot be undone. All your workouts and custom exercises will be replaced with the ones from the backup. Your settings are not affected."),
            buttons: [
                .destructive(Text("Restore"), action: {
                    do {
                        try IronBackup.restoreBackupData(data: data(), managedObjectContext: context, exerciseStore: exerciseStore)
                        completion(.success(()))
                    } catch {
                        completion(.failure(error))
                    }
                }),
                .cancel()
            ]
        )
    }
    
    static func restoreResultAlert(restoreResult: RestoreResult) -> Alert {
        switch restoreResult {
        case .success():
            return Alert(title: Text("Restore Successful"))
        case .failure(let error):
            let errorMessage: String
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case let .dataCorrupted(context):
                    errorMessage = "Data corrupted. \(context.debugDescription)"
                case let .keyNotFound(_, context):
                    errorMessage = "Key not found. \(context.debugDescription)"
                case let .typeMismatch(_, context):
                    errorMessage = "Type mismatch. \(context.debugDescription)"
                case let .valueNotFound(_, context):
                    errorMessage = "Value not found. \(context.debugDescription)"
                @unknown default:
                    errorMessage = "Decoding error. \(error.localizedDescription)"
                }
            } else {
                errorMessage = error.localizedDescription
            }
            return Alert(title: Text("Restore Failed"), message: Text(errorMessage))
        }
    }
}
