//
//  TrainingsLog.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 12.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingsLog: View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var training: Training
    
    private func trainingExerciseText(trainingExercise: TrainingExercise) -> String? {
        guard let trainingSets = trainingExercise.trainingSets else { return nil }
        let text = trainingSets
            .compactMap { $0 as? TrainingSet }
            .filter { $0.isCompleted }
            .map { $0.displayTitle(unit: settingsStore.weightUnit) }
            .joined(separator: "\n")
        return text.isEmpty ? nil : text
    }
    
    var body: some View {
        List {
            Section {
                TrainingsLogBannerView(training: training)
                    .listRowBackground(training.muscleGroupColor)
                    .environment(\.colorScheme, .dark) // TODO: check whether accent color is actually dark
            }
            Section {
                ForEach(training.trainingExercisesWhereNotAllSetsAreUncompleted ?? [], id: \.objectID) { trainingExercise in
                    VStack(alignment: .leading) {
                        Text(trainingExercise.exercise?.title ?? "")
                            .font(.body)
                        self.trainingExerciseText(trainingExercise: trainingExercise).map {
                            Text($0)
                                .font(Font.body.monospacedDigit())
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

private struct TrainingsLogBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @ObservedObject var training: Training
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
    }
    
    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()
        
        entries.append(BannerViewEntry(id: 0, title: Text("Sets"), text: Text(String(training.numberOfCompletedSets ?? 0))))
        entries.append(BannerViewEntry(id: 1, title: Text("Weight"), text: Text("\(WeightUnit.format(weight: training.totalCompletedWeight ?? 0, from: .metric, to: settingsStore.weightUnit))")))
        return entries
    }
}

#if DEBUG
struct TrainingsLog_Previews: PreviewProvider {
    static var previews: some View {
        TrainingsLog(training: mockCurrentTraining)
            .environmentObject(mockSettingsStoreMetric)
    }
}
#endif
