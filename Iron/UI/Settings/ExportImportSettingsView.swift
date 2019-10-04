//
//  ExportImportSettingsView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 17.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct ExportImportSettingsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    var body: some View {
        Form {
            Section(header: Text("Export Workout Data".uppercased())) {
                Button("As JSON File") {
                    guard let workouts = self.fetchWorkouts() else { return }
                    
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
                    encoder.dateEncodingStrategy = .iso8601
                    
                    guard let data = try? encoder.encode(workouts) else { return }
                    guard let url = self.writeFile(data: data, name: "workout_data.json") else { return }
                    self.shareFile(url: url)
                }
//                Button("As XML File") {
//                    // TODO
//                }
                Button("As Plain Text File") {
                    guard let workouts = self.fetchWorkouts() else { return }
                    
                    let text = workouts.compactMap { $0.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) }.joined(separator: "\n\n\n\n\n")
                    
                    guard let data = text.data(using: .utf8) else { return }
                    guard let url = self.writeFile(data: data, name: "workout_data.txt") else { return }
                    self.shareFile(url: url)
                }
            }
            
            Section(header: Text("Import Workout Data".uppercased())) {
                Button("From JSON File") {
                    // TODO
                }.disabled(true)
//                Button("From XML File") {
//                    // TODO
//                }
            }
        }
    }
    
    private func fetchWorkouts() -> [Workout]? {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return (try? self.managedObjectContext.fetch(request))
    }
    
    private func writeFile(data: Data, name: String) -> URL? {
        let path = FileManager.default.temporaryDirectory
        let url = path.appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            print(error)
            return nil
        }
    }
    
    private func shareFile(url: URL) {
        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        // TODO: replace this hack with a proper way to retreive the rootViewController
        guard let rootVC = (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.window?.rootViewController else { return }
        rootVC.present(ac, animated: true)
    }
}

#if DEBUG
struct ExportImportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportImportSettingsView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
