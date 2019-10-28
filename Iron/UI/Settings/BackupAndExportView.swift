//
//  BackupAndExportView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct BackupAndExportView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @State private var showExportWorkoutDataSheet = false
    
    @State private var backupError: BackupError?
    private struct BackupError: Identifiable {
         let id = UUID()
         let error: Error?
     }
     
    private func alert(backupError: BackupError) -> Alert {
        let errorMessage = backupError.error?.localizedDescription
        let text = errorMessage.map { Text($0) }
        return Alert(title: Text("Could not Create Backup"), message: text)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Export".uppercased())) {
                Button("Workout Data") {
                    self.showExportWorkoutDataSheet = true
                }
                Button("Backup") {
                    do {
                        let data = try IronBackup.createBackupData(managedObjectContext: self.managedObjectContext, exerciseStore: self.exerciseStore)
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        let dateString = formatter.string(from: Date())
                        
                        let url = try self.tempFile(data: data, name: "\(dateString).ironbackup")
                        
                        self.shareFile(url: url)
                    } catch {
                        print(error)
                        self.backupError = BackupError(error: error)
                    }
                }
            }
            
            Section(header: Text("Cloud Backup".uppercased()), footer: Text("Last backup: TODO")) { // TODO display last backup
                NavigationLink(destination: Text("TODO")) {
                    Text("Restore")
                }
                Toggle("Auto Backup", isOn: .constant(true)) // TODO
                Button("Back Up Now") {
                    UbiquityContainer.backupsUrl { result in
                        do {
                            let url = try result.get()
                            print(url)
                            
                            let data = try IronBackup.createBackupData(managedObjectContext: self.managedObjectContext, exerciseStore: self.exerciseStore)
                            
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            let dateString = formatter.string(from: Date())
                            
                            let fileUrl = url.appendingPathComponent(dateString).appendingPathExtension("ironbackup")
                            try data.write(to: fileUrl, options: .atomic)
                        } catch {
                            print(error)
                            self.backupError = BackupError(error: error)
                        }
                    }
                }
            }
        }
        .actionSheet(isPresented: $showExportWorkoutDataSheet) {
            ActionSheet(title: Text("Workout Data"), buttons: [
                .default(Text("JSON"), action: {
                    guard let workouts = self.fetchWorkouts() else { return }
                    
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
                    encoder.dateEncodingStrategy = .iso8601
                    
                    guard let data = try? encoder.encode(workouts) else { return }
                    guard let url = try? self.tempFile(data: data, name: "workout_data.json") else { return }
                    self.shareFile(url: url)
                }),
                .default(Text("TXT"), action: {
                    guard let workouts = self.fetchWorkouts() else { return }
                    
                    let text = workouts.compactMap { $0.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) }.joined(separator: "\n\n\n\n\n")
                    
                    guard let data = text.data(using: .utf8) else { return }
                    guard let url = try? self.tempFile(data: data, name: "workout_data.txt") else { return }
                    self.shareFile(url: url)
                }),
                .cancel()
            ])
        }
        .alert(item: $backupError) { backupError in
            self.alert(backupError: backupError)
        }
    }
    
    private func fetchWorkouts() -> [Workout]? {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return (try? self.managedObjectContext.fetch(request))
    }
    
    private func tempFile(data: Data, name: String) throws -> URL {
        let path = FileManager.default.temporaryDirectory
        let url = path.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
    
    private func shareFile(url: URL) {
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // TODO: replace this hack with a proper way to retreive the rootViewController
        guard let rootVC = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
        rootVC.present(ac, animated: true)
    }
}

#if DEBUG
struct BackupAndExportView_Previews: PreviewProvider {
    static var previews: some View {
        BackupAndExportView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
