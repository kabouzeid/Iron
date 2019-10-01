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

struct FeedView : View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject private var pinnedChartsStore = PinnedChartsStore.shared
    
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
                        self.exerciseStore.find(with: chart.exerciseId).map {
                            ExerciseChartViewCell(exercise: $0, measurementType: chart.measurementType)
                        }
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
                PinnedChartSelectorSheet(exercises: self.exerciseStore.exercises) { pinnedChart in
                    self.pinnedChartsStore.pinnedCharts.append(pinnedChart)
                }
                .environmentObject(self.pinnedChartsStore)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct PinnedChartSelectorSheet: View {
    @EnvironmentObject var pinnedChartsStore: PinnedChartsStore
    
    @Environment(\.presentationMode) var presentationMode

    let onSelection: (PinnedChart) -> Void
    
    @State private var selectedExercise: Exercise? = nil

    @ObservedObject private var filter: ExerciseGroupFilter
    
    init(exercises: [Exercise], onSelection: @escaping (PinnedChart) -> Void) {
        filter = ExerciseGroupFilter(exercises: ExerciseStore.splitIntoMuscleGroups(exercises: exercises))
        self.onSelection = onSelection
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.filter.filter = ""
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
            VStack(spacing: 0) {
                SheetBar(title: "Add Widget", leading: Button("Cancel") { self.resetAndDismiss() }, trailing: EmptyView())
                TextField("Search", text: $filter.filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter.filter))
                    .padding(.top)
            }.padding()
            
            ExerciseSingleSelectionView(exerciseMuscleGroups: filter.exercises) { exercise in
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
                .mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
}
#endif
