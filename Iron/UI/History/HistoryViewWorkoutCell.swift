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
                        viewModel.bodyPartLetter.map { letter in
                            viewModel.bodyPartColor.map { color in
                                Label(viewModel.title, systemImage: letter)
                                    .font(.headline)
                                    .symbolVariant(.circle.fill)
                                    .foregroundStyle(color)
                            }
                        }
                        
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
        let bodyWeight: Double?
        
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
            let totalWeight = workoutInfo.workoutExerciseInfos.reduce(0) { partialResult, workoutExerciseInfo in
                workoutExerciseInfo.workoutSets.reduce(0) { partialResult, workoutSet in
                    workoutSet.isCompleted ? (workoutSet.weight ?? 0 * Double(workoutSet.repetitions ?? 0)) : 0
                }
            }
            return Measurement(value: totalWeight, unit: UnitMass.kilograms).formatted()
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
            bodyWeight.map { "\($0.formatted()) kg" }
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

//#if DEBUG
//struct HistoryViewWorkoutCell_Previews : PreviewProvider {
//    static var previews: some View {
//        HistoryView.WorkoutCell(viewModel: .init(workoutInfo: workoutA, prInfo: nil, bodyWeight: 82))
//            .scenePadding()
//            .previewLayout(.sizeThatFits)

//        HistoryView.WorkoutCell(viewModel: .init(workoutInfo: workoutB, bodyWeight: 81.3))
//            .scenePadding()
//            .previewLayout(.sizeThatFits)
//
//        HistoryView.WorkoutCell(viewModel: .init(workoutInfo: workoutB, bodyWeight: nil))
//            .scenePadding()
//            .previewLayout(.sizeThatFits)
//    }
//
//    static var workoutA: AppDatabase.WorkoutInfo {
//        var workout = Workout.new(start: Date(timeIntervalSinceNow: -60*60*1.5))
//        workout.end = Date()
//        workout.comment = "Feeling strong today"
//        workout.title = "Chest & Arms"
//        return workout
//    }

//    static var workoutB: AppDatabase.WorkoutInfo {
//        var workout = Workout.new(start: Date(timeIntervalSinceNow: -60*60*1.5))
//        workout.end = Date()
//        workout.title = "Back"
//        return workout
//    }
//}
//#endif
