//
//  HistoryViewWorkoutCell.swift
//  Iron
//
//  Created by Karim Abou Zeid on 02.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import IronData

extension HistoryView {
    struct WorkoutCell: View {
        let viewModel: ViewModel
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(viewModel.title, systemImage: viewModel.bodyPartLetter ?? "questionmark")
                            .font(.headline)
                            .symbolVariant(.circle.fill)
                            .foregroundStyle(viewModel.bodyPartColor ?? .black)
                        
                        Label(viewModel.startString, systemImage: "calendar")
                            .font(.body)
                            .labelStyle(.titleOnly)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        
                        HStack(spacing: 24) {
                            Label(viewModel.durationString, systemImage: "clock")
                                .font(.body)
                            
                            Label(viewModel.totalWeight, systemImage: "scalemass")
                                .font(.body)
                            
                            viewModel.bodyWeightFormatted.map {
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
                                
                                if (item.containsPR) {
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

extension HistoryView.WorkoutCell {
    struct ViewModel {
        static let durationFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            return formatter
        }()
        
        let workoutInfo: HistoryView.ViewModel.WorkoutInfo
        let personalRecordInfo: HistoryView.ViewModel.PersonalRecordInfo?
        let bodyWeight: Measurement<UnitMass>?
        
        var title: String {
            workoutInfo.workout.displayTitle(
                infos: workoutInfo.workoutExerciseInfos.map { (exercise: $0.exercise, workoutSets: $0.workoutSets) }
            )
        }
        
        private var generatedTitle: String? {
            let bodyParts = bodyParts
            switch bodyParts.count {
            case 1:
                return bodyParts[0].name.capitalized
            case 2...:
                return "\(bodyParts[0].name.capitalized) & \(bodyParts[1].name.capitalized)"
            default:
                return nil
            }
        }
        
        var comment: String? {
            workoutInfo.workout.comment
        }
        
        var startString: String {
            workoutInfo.workout.start.formatted(date: .abbreviated, time: .shortened)
        }
        
        var durationString: String {
            {
                guard let duration = workoutInfo.workout.dateInterval?.duration else { return nil }
                return Self.durationFormatter.string(from: duration)
            }() ?? "Unknown Duration"
        }
        
        var totalWeight: String {
            workoutInfo.workout.totalWeight(
                infos: workoutInfo.workoutExerciseInfos.map { $0.workoutSets }
            ).formatted()
        }
        
        var summary: [SummaryItem] {
            workoutInfo.workoutExerciseInfos.map { workoutExerciseInfo in
                SummaryItem(
                    exerciseDescription: "\(workoutExerciseInfo.workoutSets.count) × \(workoutExerciseInfo.exercise.title)",
                    containsPR: personalRecordInfo?[workoutExerciseInfo.workoutExercise.id!] ?? false
                )
            }
        }
        
        struct SummaryItem: Identifiable {
            let exerciseDescription: String
            let containsPR: Bool
            
            var id: UUID { UUID() } // there are no ids for this item
        }
        
        var bodyWeightFormatted: String? {
            bodyWeight.map { $0.formatted() }
        }
        
        private var bodyParts: [Exercise.BodyPart] {
            workoutInfo.workoutExerciseInfos.flatMap { workoutExerciseInfo in
                workoutExerciseInfo.exercise.bodyPart.map { bodyPart in
                    Array(repeating: bodyPart, count: max(workoutExerciseInfo.workoutSets.count, 1))
                } ?? []
            }.sortedByFrequency().uniqed().reversed()
        }
        
        var bodyPartLetter: String? {
            bodyParts.first?.letter
        }
        
        var bodyPartColor: Color? {
            bodyParts.first?.color
        }
    }
}

#if DEBUG
struct HistoryViewWorkoutCell_Previews : PreviewProvider {
    static var previews: some View {
        HistoryView.WorkoutCell(
            viewModel: .init(workoutInfo: workoutInfo, personalRecordInfo: [0 : false, 1 : true], bodyWeight: .init(value: 82, unit: .kilograms))
        )
        .scenePadding()
        .previewLayout(.sizeThatFits)
    }
    
    static var workoutInfo: HistoryView.ViewModel.WorkoutInfo {
        var workout = Workout.new(start: Date(timeIntervalSinceNow: -60*60*1.5))
        workout.end = Date()
        workout.comment = "Feeling strong today"
        
        var exercise1 = Exercise.new(title: "Bench Press: Barbell", category: .barbell)
        exercise1.bodyPart = .chest
        exercise1.id = 0
        var workoutExercise1 = WorkoutExercise.new(exerciseId: 0, workoutId: 0)
        workoutExercise1.id = 0
        var workoutSet1 = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet1.id = 0
        workoutSet1.weight = 100
        workoutSet1.repetitions = 5
        workoutSet1.isCompleted = true
        
        var exercise2 = Exercise.new(title: "Squat: Barbell", category: .barbell)
        exercise2.bodyPart = .legs
        exercise2.id = 1
        var workoutExercise2 = WorkoutExercise.new(exerciseId: 1, workoutId: 0)
        workoutExercise2.id = 1
        var workoutSet2 = WorkoutSet.new(workoutExerciseId: 1)
        workoutSet2.id = 1
        workoutSet2.weight = 140
        workoutSet2.repetitions = 5
        workoutSet2.isCompleted = true
        
        return .init(workout: workout, workoutExerciseInfos: [
            .init(workoutExercise: workoutExercise1, exercise: exercise1, workoutSets: [workoutSet1]),
            .init(workoutExercise: workoutExercise2, exercise: exercise2, workoutSets: [workoutSet2])
        ])
    }
}
#endif
