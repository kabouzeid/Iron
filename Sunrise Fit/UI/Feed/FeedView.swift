//
//  FeedView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import Combine

private class PinnedChartsStore: BindableObject {
    var willChange = PassthroughSubject<Void, Never>()
    
    var pinnedCharts: [PinnedChart] {
        get {
            UserDefaults.standard.pinnedCharts
        }
        set {
            willChange.send()
            UserDefaults.standard.pinnedCharts = newValue
        }
    }
}

struct FeedView : View {
    @ObjectBinding private var pinnedChartsStore = PinnedChartsStore()
    
    @State private var showingPinnedChartSelector = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    ActivityChartViewCell()
                    FeedBannerView()
                }
                
                Section {
                    ForEach(pinnedChartsStore.pinnedCharts, id: \.self) { chart in
                        ExerciseChartViewCell(exercise: EverkineticDataProvider.findExercise(id: chart.exerciseId)!, measurementType: chart.measurementType)
                    }
                    .onDelete { offsets in
                        self.pinnedChartsStore.pinnedCharts.remove(atOffsets: offsets)
                    }
                    .onMove { source, destination in
                        self.pinnedChartsStore.pinnedCharts.move(fromOffsets: source, toOffset: destination)
                    }
                    Button(action: {
                        self.showingPinnedChartSelector = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Widget")
                        }
                    }
                }
            }
            .listStyle(.grouped)
            .navigationBarTitle(Text("Feed"))
            .navigationBarItems(trailing: EditButton())
            .sheet(isPresented: $showingPinnedChartSelector) {
                VStack(alignment: .leading) {
                    Button("Cancel") {
                        self.showingPinnedChartSelector = false
                    }.padding()
                    PinnedChartSelectorView(pinnedChartsStore: self.pinnedChartsStore, exerciseMuscleGroups: EverkineticDataProvider.exercisesGrouped) { pinnedChart in
                        self.pinnedChartsStore.pinnedCharts.append(pinnedChart)
                        self.showingPinnedChartSelector = false
                    }
                }
            }
        }
    }
}

private struct PinnedChartSelectorView: View {
    @ObjectBinding var pinnedChartsStore: PinnedChartsStore
    
    var exerciseMuscleGroups: [[Exercise]]
    var onSelection: (PinnedChart) -> Void
    
    @State private var selectedExercise: Exercise? = nil
    
    private func actionButtons(exercise: Exercise) -> [ActionSheet.Button] {
        TrainingExerciseChartDataGenerator.MeasurementType.allCases.compactMap { measurementType in
            let pinnedChart = PinnedChart(exerciseId: exercise.id, measurementType: measurementType)
            if self.pinnedChartsStore.pinnedCharts.contains(pinnedChart) {
                return nil
            } else {
                return .default(Text(measurementType.title)) { self.onSelection(pinnedChart) }
            }
        } + [.cancel()]
    }
    
    var body: some View {
        List {
            ForEach(exerciseMuscleGroups, id: \.first?.muscleGroup) { exercises in
                Section(header: Text(exercises.first?.muscleGroup.capitalized ?? "")) {
                    ForEach(exercises, id: \.self) { exercise in
                        Button(exercise.title) {
                            self.selectedExercise = exercise
                        }
                    }
                }
            }
        }
        .actionSheet(item: $selectedExercise) { exercise in
            ActionSheet(title: Text(exercise.title), message: nil, buttons: actionButtons(exercise: exercise))
        }
    }
}

#if DEBUG
struct FeedView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            FeedView()
                .environmentObject(mockTrainingsDataStore)
                .environmentObject(mockSettingsStoreMetric)
                
                // TODO: remove in future, somehow necessary (beta 4)
                .listStyle(.grouped)
        }
    }
}
#endif
