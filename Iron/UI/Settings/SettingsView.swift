//
//  SettingsView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 11.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine
import CoreData
import UIKit

struct SettingsView : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        NavigationView {
            Form {
                Picker("Weight Unit", selection: $settingsStore.weightUnit) {
                    ForEach(WeightUnit.allCases, id: \.self) { weightUnit in
                        Text(weightUnit.title).tag(weightUnit)
                    }
                }
                
                Section {
                    Picker("Default Rest Time", selection: $settingsStore.defaultRestTime) {
                        ForEach(restTimerCustomTimes, id: \.self) { time in
                            Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                        }
                    }
                    Picker("Default Rest Time (Barbell)", selection: $settingsStore.defaultRestTimeBarbellBased) {
                        ForEach(restTimerCustomTimes, id: \.self) { time in
                            Text(restTimerDurationFormatter.string(from: time) ?? "").tag(time)
                        }
                    }
                }
                
                Section(footer: Text("Maximum number of repetitions for a set to be considered in the one rep max (1RM) calculation. Keep in mind that higher values are less accurate.")) {
                    Picker("Max Repetitions for 1RM", selection: $settingsStore.maxRepetitionsOneRepMax) {
                        ForEach(maxRepetitionsOneRepMaxValues, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                }
                
                Section {
                    Button("Export workout data as JSON") {
                        guard let trainings = self.fetchTrainings() else { return }
                        
                        let encoder = JSONEncoder()
                        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
                        encoder.dateEncodingStrategy = .iso8601
                        
                        guard let data = try? encoder.encode(trainings) else { return }
                        guard let url = self.writeFile(data: data, name: "workout_data.json") else { return }
                        self.shareFile(url: url)
                    }
                    Button("Export workout data as Plain Text") {
                        guard let trainings = self.fetchTrainings() else { return }
                        
                        let text = trainings.compactMap { $0.logText(weightUnit: self.settingsStore.weightUnit) }.joined(separator: "\n\n\n\n\n")

                        guard let data = text.data(using: .utf8) else { return }
                        guard let url = self.writeFile(data: data, name: "workout_data.txt") else { return }
                        self.shareFile(url: url)
                    }
//                    Button("Import workout data from JSON") {
//                        // TODO
//                    }
                }
            }
            .navigationBarTitle(Text("Settings"))
        }
    }
    
    private func fetchTrainings() -> [Training]? {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Training.isCurrentTraining)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Training.start, ascending: false)]
        return (try? self.managedObjectContext.fetch(request))
    }
    
    private func writeFile(data: Data, name: String) -> URL? {
        guard let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
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
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
