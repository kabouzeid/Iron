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
import WorkoutDataKit

struct FeedView : View {
    @EnvironmentObject var exerciseStore: ExerciseStore
    @ObservedObject private var pinnedChartsStore = PinnedChartsStore.shared
    
    @State private var activeSheet: SheetType?
    
    private enum SheetType: Identifiable {
        case pinnedChartSelector
        case pinnedChartEditor
        
        var id: Self { self }
    }
    
    private func sheetView(type: SheetType) -> AnyView {
        switch type {
        case .pinnedChartSelector:
            return PinnedChartSelectorSheet(exercises: self.exerciseStore.shownExercises) { pinnedChart in
                self.pinnedChartsStore.pinnedCharts.append(pinnedChart)
            }
            .environmentObject(self.pinnedChartsStore)
            .typeErased
        case .pinnedChartEditor:
            return PinnedChartEditSheet()
                .environmentObject(pinnedChartsStore)
                .environmentObject(exerciseStore)
                .typeErased
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ActivityWorkoutsPerWeekCell()
                }
                
                Section {
                    ActivitySummaryLast7DaysCell()
                }
                
                ForEach(pinnedChartsStore.pinnedCharts, id: \.self) { chart in
                    if let exercise = self.exerciseStore.find(with: chart.exerciseUuid) {
                        Section {
                            ExerciseChartViewCell(exercise: exercise, measurementType: chart.measurementType)
                        }
                    }
                }
                
                Button(action: {
                    activeSheet = .pinnedChartSelector
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Pin Chart")
                    }
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .navigationBarTitle(Text("Feed"))
            .navigationBarItems(trailing: Button("Edit") { activeSheet = .pinnedChartEditor })
            .sheet(item: $activeSheet) { type in
                sheetView(type: type)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct PinnedChartEditSheet: View {
    @EnvironmentObject var pinnedChartsStore: PinnedChartsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Edit Charts", leading: Button("Close") { self.presentationMode.wrappedValue.dismiss() }, trailing: EmptyView()).padding()
            
            Divider()
            
            List {
                ForEach(pinnedChartsStore.pinnedCharts, id: \.self) { chart in
                    Text((exerciseStore.find(with: chart.exerciseUuid)?.title ?? "Unknown Exercise") + " (\(chart.measurementType.title))")
                }
                .onDelete { offsets in
                    self.pinnedChartsStore.pinnedCharts.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    self.pinnedChartsStore.pinnedCharts.move(fromOffsets: source, toOffset: destination)
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
            .placeholder(show: pinnedChartsStore.pinnedCharts.isEmpty,
                         VStack {
                            Spacer()
                            
                            Text("You don't have any charts pinned.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding()
                            
                            Spacer()
                         }
            )
        }
        .environment(\.editMode, .constant(.active))
    }
}

private struct PinnedChartSelectorSheet: View {
    @EnvironmentObject var pinnedChartsStore: PinnedChartsStore
    
    @Environment(\.presentationMode) var presentationMode

    let onSelection: (PinnedChart) -> Void
    
    @State private var selectedExercise: Exercise? = nil

    @ObservedObject private var filter: ExerciseGroupFilter
    
    init(exercises: [Exercise], onSelection: @escaping (PinnedChart) -> Void) {
        filter = ExerciseGroupFilter(exerciseGroups: ExerciseStore.splitIntoMuscleGroups(exercises: exercises))
        self.onSelection = onSelection
    }
    
    private func resetAndDismiss() {
        self.presentationMode.wrappedValue.dismiss()
        self.filter.filter = ""
    }
    
    private func actionButtons(exercise: Exercise) -> [ActionSheet.Button] {
        WorkoutExerciseChartData.MeasurementType.allCases.compactMap { measurementType in
            let pinnedChart = PinnedChart(exerciseUuid: exercise.uuid, measurementType: measurementType)
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
                SheetBar(title: "Pin Chart", leading: Button("Cancel") { self.resetAndDismiss() }, trailing: EmptyView())
                TextField("Search", text: $filter.filter)
                    .textFieldStyle(SearchTextFieldStyle(text: $filter.filter))
                    .padding(.top)
            }.padding()
            
            Divider()
            
            ExerciseSingleSelectionView(exerciseGroups: filter.exerciseGroups) { exercise in
                guard UIDevice.current.userInterfaceIdiom != .pad else { // TODO: actionSheet not supported on iPad yet (13.2)
                    // for now just add the first measuremnt type
                    for measurementType in WorkoutExerciseChartData.MeasurementType.allCases {
                        let pinnedChart = PinnedChart(exerciseUuid: exercise.uuid, measurementType: measurementType)
                        if !self.pinnedChartsStore.pinnedCharts.contains(pinnedChart) {
                            self.onSelection(pinnedChart)
                            self.resetAndDismiss()
                            return
                        }
                    }
                    return
                }
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
