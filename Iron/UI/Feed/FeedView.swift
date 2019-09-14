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

private class PinnedChartsStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    var pinnedCharts: [PinnedChart] {
        get {
            UserDefaults.standard.pinnedCharts
        }
        set {
            self.objectWillChange.send()
            UserDefaults.standard.pinnedCharts = newValue
        }
    }
}

struct FeedView : View {
    @ObservedObject private var pinnedChartsStore = PinnedChartsStore()
    
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
                        ExerciseChartViewCell(exercise: Exercises.findExercise(id: chart.exerciseId)!, measurementType: chart.measurementType)
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
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text("Feed"))
            .navigationBarItems(trailing: EditButton())
            .sheet(isPresented: $showingPinnedChartSelector) {
                PinnedChartSelectorSheet(pinnedChartsStore: self.pinnedChartsStore, exerciseMuscleGroups: Exercises.exercisesGrouped) { pinnedChart in
                    self.pinnedChartsStore.pinnedCharts.append(pinnedChart)
                }
            }
        }
    }
}

private struct PinnedChartSelectorSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var pinnedChartsStore: PinnedChartsStore
    
    var exerciseMuscleGroups: [[Exercise]]
    var onSelection: (PinnedChart) -> Void
    
    @State private var selectedExercise: Exercise? = nil
    @State private var filter = ""
    
    private var exercises: [[Exercise]] {
        Exercises.filterExercises(exercises: Exercises.exercisesGrouped, using: filter)
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.filter = ""
    }
    
    private func actionButtons(exercise: Exercise) -> [ActionSheet.Button] {
        TrainingExerciseChartDataGenerator.MeasurementType.allCases.compactMap { measurementType in
            let pinnedChart = PinnedChart(exerciseId: exercise.id, measurementType: measurementType)
            if self.pinnedChartsStore.pinnedCharts.contains(pinnedChart) {
                return nil
            } else {
                return .default(Text(measurementType.title)) {
                    self.onSelection(pinnedChart)
                    self.resetAndDismiss()
                }
            }
        } + [.cancel()]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                SheetBar(title: nil, leading: Button("Cancel") { self.resetAndDismiss() }, trailing: EmptyView())
                TextField("Search", text: $filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter))
            }.padding()
            ExerciseSingleSelectionView(exerciseMuscleGroups: exercises) { exercise in
                self.selectedExercise = exercise
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
                .environmentObject(mockSettingsStoreMetric)
                .environment(\.managedObjectContext, mockManagedObjectContext)
        }
    }
}
#endif
