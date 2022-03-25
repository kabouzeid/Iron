//
//  HistoryView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 24.03.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import IronData

struct HistoryView: View {
    @StateObject var viewModel: ViewModel = ViewModel(database: AppDatabase.shared)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.workouts) { workout in
                        NavigationLink(destination: Text("TODO")) {
                            WorkoutCell(viewModel: .init(workout: workout))
                                .contentShape(Rectangle())
                            //                            .contextMenu {
                            //                                // TODO add images when SwiftUI fixes the image size
                            //                                if UIDevice.current.userInterfaceIdiom != .pad {
                            //                                    // not working on iPad, last checked iOS 13.4
                            //                                    Button("Share") {
                            //                                        guard let logText = workout.logText(in: self.exerciseStore.exercises, weightUnit: self.settingsStore.weightUnit) else { return }
                            //                                        self.activityItems = [logText]
                            //                                    }
                            //                                }
                            //                                Button("Repeat") {
                            //                                    WorkoutDetailView.repeatWorkout(workout: workout, settingsStore: self.settingsStore, sceneState: sceneState)
                            //                                }
                            //                                Button("Repeat (Blank)") {
                            //                                    WorkoutDetailView.repeatWorkoutBlank(workout: workout, settingsStore: self.settingsStore, sceneState: sceneState)
                            //                                }
                            //                            }
                        }
                        .buttonStyle(.plain)
                        .scenePadding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(10)
                    }
                    //                .onDelete { offsets in
                    //                    if self.needsConfirmBeforeDelete(offsets: offsets) {
                    //                        self.offsetsToDelete = offsets
                    //                    } else {
                    //                        self.deleteAt(offsets: offsets)
                    //                    }
                    //                }
                }
                .scenePadding(.horizontal)
                //                .padding([.horizontal], 4)
            }
            .navigationBarItems(trailing: EditButton())
            //            .actionSheet(item: $offsetsToDelete) { offsets in
            //                ActionSheet(title: Text("This cannot be undone."), buttons: [
            //                    .destructive(Text("Delete Workout"), action: {
            //                        self.deleteAt(offsets: offsets)
            //                    }),
            //                    .cancel()
            //                ])
            //            }
            .background(Color(uiColor: .systemGroupedBackground))
            .placeholder(show: viewModel.workouts.isEmpty, Text("Your finished workouts will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            )
            .navigationBarTitle(Text("History"))
            
            // Double Column Placeholder
            Text("No workout selected")
                .foregroundColor(.secondary)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        //        .background(Color(UIColor.systemGroupedBackground))
        //        .overlay(ActivitySheet(activityItems: self.$activityItems))
        .task {
            try! await viewModel.fetchData()
        }
    }
    
    struct WorkoutCell: View {
        let viewModel: ViewModel
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                    Label(viewModel.title, systemImage: viewModel.bodyPartLetter)
                        .font(.headline)
                        .symbolVariant(.circle.fill)
                        .foregroundStyle(viewModel.bodyPartColor)
//                        .foregroundStyle(.orange)
                    
                    Label(viewModel.startString, systemImage: "calendar")
                        .font(.body)
                        .labelStyle(.titleOnly)
//                        .foregroundColor(.blue)
                        .foregroundColor(.secondary)
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        
                        HStack(spacing: 24) {
                            Label(viewModel.durationString, systemImage: "clock")
                                .font(.body)
                            
                            Label(viewModel.totalWeight, systemImage: "scalemass")
                                .font(.body)
                            
                            viewModel.bodyWeight.map {
                                Label($0, systemImage: "person")
                                    .font(.body)
                            }
                        }
                        
                        Divider()
                    }
                    
                    
                    viewModel.comment.map {
                        Text($0.enquoted)
                            .lineLimit(1)
                            .font(Font.body.italic())
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.summary) { item in
                            HStack {
                                Text(item.exerciseDescription)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if (item.isPR) {
                                    Image(systemName: "star")
                                        .symbolVariant(.circle.fill)
                                        .symbolRenderingMode(.multicolor)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

extension HistoryView {
    @MainActor
    class ViewModel: ObservableObject {
        let database: AppDatabase
        
        @Published var workouts: [IronData.Workout] = []
        
        nonisolated init(database: AppDatabase) {
            self.database = database
        }
        
        func fetchData() async throws {
            for try await workouts in database.workouts() {
                self.workouts = workouts
            }
        }
    }
}

extension HistoryView.WorkoutCell {
    struct ViewModel {
        static let durationFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            return formatter
        }()
        
        let workout: Workout
        
        var title: String {
            workout.title ?? "Untitled"
            // TODO: use "display title" dependent on exercises etc
        }
        
        var comment: String? {
            workout.comment
        }
        
        var startString: String {
            workout.start.formatted(date: .abbreviated, time: .shortened)
        }
        
        var durationString: String {
            {
                guard let duration = workout.dateInterval?.duration else { return nil }
                return Self.durationFormatter.string(from: duration)
            }() ?? "Unknown Duration"
        }
        
        private let _totalWeight = "\(Int.random(in: 2000...10000).formatted()) kg"
        var totalWeight: String {
            _totalWeight
        }
        
        var summary: [SummaryItem] {
            [
                SummaryItem(exerciseDescription: "5 × Squat: Barbell", isPR: Int.random(in: 0..<5) == 0),
                SummaryItem(exerciseDescription: "5 × Bench Press: Barbell", isPR: Int.random(in: 0..<5) == 0),
                SummaryItem(exerciseDescription: "3 × Dips", isPR: Int.random(in: 0..<5) == 0),
                SummaryItem(exerciseDescription: "3 × Triceps Extensions", isPR: Int.random(in: 0..<5) == 0)
            ]
        }
        
        struct SummaryItem: Identifiable {
            let exerciseDescription: String
            let isPR: Bool
            
            var id: UUID { UUID() } // there are no ids for this item
        }
        
        private let _bodyWeight = "\((Double(Int.random(in: 160...166)) / 2).formatted()) kg"
        var bodyWeight: String? {
            _bodyWeight
        }
        
        private let _bodyPart = Exercise.BodyPart.allCases.randomElement()!
        private var bodyPart: Exercise.BodyPart {
            _bodyPart
        }
        
        var bodyPartColor: Color {
            switch bodyPart {
            case .core:
                return .teal
            case .arms:
                return .purple
            case .shoulders:
                return .orange
            case .back:
                return .blue
            case .legs:
                return .green
            case .chest:
                return .red
            }
        }
        
        var bodyPartLetter: String {
            switch bodyPart {
            case .core:
                return "c"
            case .arms:
                return "a"
            case .shoulders:
                return "s"
            case .back:
                return "b"
            case .legs:
                return "l"
            case .chest:
                return "c"
            }
        }
    }
}

#if DEBUG
struct HistoryView_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView.WorkoutCell(viewModel: .init(workout: workoutA))
            .padding()
            .previewLayout(.sizeThatFits)
        
        HistoryView.WorkoutCell(viewModel: .init(workout: workoutB))
            .padding()
            .previewLayout(.sizeThatFits)
        
        TabView {
            HistoryView(viewModel: .init(database: .random()))
                .mockEnvironment(weightUnit: .metric, isPro: true)
        }
    }
    
    static var workoutA: Workout {
        var workout = Workout.new(start: Date(timeIntervalSinceNow: -60*60*1.5))
        workout.end = Date()
        workout.comment = "Feeling strong today"
        workout.title = "Chest & Arms"
        return workout
    }
    
    static var workoutB: Workout {
        var workout = Workout.new(start: Date(timeIntervalSinceNow: -60*60*1.5))
        workout.end = Date()
        workout.title = "Back"
        return workout
    }
}
#endif
