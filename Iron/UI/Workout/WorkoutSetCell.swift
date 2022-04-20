//
//  ActiveWorkoutSetCell.swift
//  Iron
//
//  Created by Karim Abou Zeid on 09.04.22.
//  Copyright © 2022 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

extension WorkoutView {
    struct SetCell: View {
        let viewModel: ViewModel
        
        var body: some View {
            HStack {
                switch viewModel.state {
                case .next:
                    Image(systemName: "chevron.right.circle.fill")
                        .foregroundColor(.accentColor)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .pending:
                    EmptyView()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        let title = viewModel.title
                        Text(title ?? "Set")
                            .font(Font.body.monospacedDigit())
                            .foregroundColor(title == nil ? .secondary : .primary)
                            .overlay(
                                Group {
                                    if viewModel.isSelected {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .stroke(Color.accentColor)
                                            .padding(-4)
                                    }
                                }
                            )
                        
                        if let hint = viewModel.target {
                            HStack(spacing: 2) {
                                Image(systemName: "target")
                                Text(hint)
                            }
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        }
                    }
                    
                    if viewModel.isPersonalRecord1RM {
                        HStack {
                            if viewModel.isPersonalRecord1RM {
                                personalRecordView("1RM")
                            }
                            
                            if viewModel.isPersonalRecordWeight {
                                personalRecordView("Weight")
                            }
                            
                            if viewModel.isPersonalRecordVolume {
                                personalRecordView("Volume")
                            }
                        }
                    }
                    
                    if let comment = viewModel.comment {
                        Text(comment.enquoted)
                            .lineLimit(1)
                            .font(Font.caption.italic())
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let rpe = viewModel.rpe {
                    Text("\(rpe)").font(.caption)
                }
                
                Text("\(viewModel.index)")
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(viewModel.tag == nil ? .secondary : .clear)
                    .background(
                        Group {
                            if let tag = viewModel.tag {
                                Text(tag.label)
                                    .fontWeight(.semibold)
                                    .foregroundColor(tag.color)
                                    .fixedSize()
                            }
                        }
                    )
            }
            .padding(.vertical, 6)
        }
        
        func personalRecordView(_ title: String) -> some View {
            HStack(spacing: 2) {
                Image(systemName: "star.circle.fill")
                Text(title)
            }
            .foregroundColor(.yellow)
            .font(.caption.bold())
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder()
                    .foregroundColor(.yellow)
            )
        }
    }
}

import IronData
extension WorkoutView.SetCell {
    struct ViewModel {
        let workoutSet: WorkoutSet
        let exerciseCategory: Exercise.Category
        
        let index: Int
        let state: State
        let isSelected: Bool
        
        let isPersonalRecord1RM: Bool
        let isPersonalRecordWeight: Bool
        let isPersonalRecordVolume: Bool
        
        var massFormat: MassFormat = SettingsStore.shared.massFormat
        
        enum State {
            case completed, next, pending
        }
        
        var title: String? {
            guard state != .pending else { return nil }
            
            switch exerciseCategory {
            case .barbell, .dumbbell, .machine, .bodyweight:
                return "\(massFormat.format(kg: workoutSet.weight ?? 0)) × \(workoutSet.repetitions ?? 0)"
            case .cardio:
                let distance = Measurement(value: workoutSet.weight ?? 0, unit: UnitLength.kilometers)
                let duration = Double(workoutSet.repetitions ?? 0)
                
                return (distance.value > 0 ? distance.formatted() + " in " : "") + (Self.durationFormatter.string(from: duration) ?? "")
            case .duration:
                return "\(Self.durationFormatter.string(from: Double(workoutSet.repetitions ?? 0)) ?? "")"
            }
        }
        
        var target: String? {
            switch exerciseCategory {
            case .barbell, .dumbbell, .machine, .bodyweight:
                // NOTE: we use an en-dash, not a hyphen
                if let minRepetitions = workoutSet.targetRepetitionsLower {
                    if let maxRepetitions = workoutSet.targetRepetitionsUpper {
                        return "\(minRepetitions == maxRepetitions ? "\(maxRepetitions)" : "\(minRepetitions)–\(maxRepetitions)")"
                    } else {
                        return "\(minRepetitions)+"
                    }
                } else if let maxRepetitions = workoutSet.targetRepetitionsUpper {
                    return "\(maxRepetitions)-"
                } else {
                    return nil
                }
            case .cardio, .duration:
                return nil
            }
        }
        
        var comment: String? {
            workoutSet.comment
        }
        
        var rpe: String? {
            workoutSet.rpe.map { Self.rpeFormatter.string(from: $0 as NSNumber) } ?? nil
        }
        
        var tag: (label: String, color: Color)? {
            switch workoutSet.tag {
            case .warmup:
                return ("W", .orange)
            case .dropset:
                return ("D", .purple)
            case .failure:
                return ("F", .red)
            case nil:
                return nil
            }
        }
        
        static let durationFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute, .second]
            return formatter
        }()
        
        private static var rpeFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 1
            return formatter
        }()
    }
}

struct ActiveWorkoutSetCell_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Section {
                WorkoutView.SetCell(
                    viewModel: .init(workoutSet: workoutSetInfo1.0, exerciseCategory: workoutSetInfo1.1, index: 1, state: .completed, isSelected: false, isPersonalRecord1RM: true, isPersonalRecordWeight: true, isPersonalRecordVolume: false)
                )
                
                WorkoutView.SetCell(
                    viewModel: .init(workoutSet: workoutSetInfo1.0, exerciseCategory: workoutSetInfo1.1, index: 2, state: .completed, isSelected: false, isPersonalRecord1RM: false, isPersonalRecordWeight: false, isPersonalRecordVolume: false)
                )
                
                WorkoutView.SetCell(
                    viewModel: .init(workoutSet: workoutSetInfo1.0, exerciseCategory: workoutSetInfo1.1, index: 3, state: .next, isSelected: true, isPersonalRecord1RM: false, isPersonalRecordWeight: false, isPersonalRecordVolume: false)
                )
                
                WorkoutView.SetCell(
                    viewModel: .init(workoutSet: workoutSetInfo1.0, exerciseCategory: workoutSetInfo1.1, index: 4, state: .pending, isSelected: false, isPersonalRecord1RM: false, isPersonalRecordWeight: false, isPersonalRecordVolume: false)
                )
            }
            
            Section {
                WorkoutView.SetCell(viewModel: .init(workoutSet: workoutSetInfo3.0, exerciseCategory: workoutSetInfo3.1, index: 1, state: .completed, isSelected: false, isPersonalRecord1RM: false, isPersonalRecordWeight: false, isPersonalRecordVolume: false))
            }
            
            Section {
                WorkoutView.SetCell(viewModel: .init(workoutSet: workoutSetInfo4.0, exerciseCategory: workoutSetInfo4.1, index: 1, state: .completed, isSelected: false, isPersonalRecord1RM: false, isPersonalRecordWeight: false, isPersonalRecordVolume: false))
            }
            
            Section {
                WorkoutView.SetCell(
                    viewModel: .init(workoutSet: workoutSetInfo2.0, exerciseCategory: workoutSetInfo2.1, index: 1, state: .completed, isSelected: false, isPersonalRecord1RM: false, isPersonalRecordWeight: false, isPersonalRecordVolume: false)
                )
            }
        }
        .previewLayout(.sizeThatFits)
    }

    static var workoutSetInfo1: (WorkoutSet, Exercise.Category) {
        var exercise = Exercise.new(title: "Bench Press: Barbell", category: .barbell)
        exercise.bodyPart = .chest
        exercise.id = 0
        var workoutExercise = WorkoutExercise.new(exerciseId: 0, workoutId: 0)
        workoutExercise.id = 0

        var workoutSet = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet.id = 0
        workoutSet.weight = 100
        workoutSet.repetitions = 5
        workoutSet.isCompleted = true

        return (workoutSet, exercise.category)
    }

    static var workoutSetInfo2: (WorkoutSet, Exercise.Category) {
        var exercise = Exercise.new(title: "Running", category: .cardio)
        exercise.bodyPart = .legs
        exercise.id = 0
        var workoutExercise = WorkoutExercise.new(exerciseId: 0, workoutId: 0)
        workoutExercise.id = 0

        var workoutSet = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet.id = 1
        workoutSet.weight = 9
        workoutSet.repetitions = 60*43 + 19
        workoutSet.comment = "Left knee was hurting"
        workoutSet.isCompleted = true

        return (workoutSet, exercise.category)
    }
    
    static var workoutSetInfo3: (WorkoutSet, Exercise.Category) {
        var exercise = Exercise.new(title: "Squat: Barbell", category: .barbell)
        exercise.bodyPart = .legs
        exercise.id = 0
        var workoutExercise = WorkoutExercise.new(exerciseId: 0, workoutId: 0)
        workoutExercise.id = 0

        var workoutSet = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet.id = 1
        workoutSet.weight = 140
        workoutSet.repetitions = 3
        workoutSet.rpe = 9.5
        workoutSet.tag = .failure
        workoutSet.isCompleted = true

        return (workoutSet, exercise.category)
    }
    
    static var workoutSetInfo4: (WorkoutSet, Exercise.Category) {
        var exercise = Exercise.new(title: "Deadlift: Barbell", category: .barbell)
        exercise.bodyPart = .back
        exercise.id = 0
        var workoutExercise = WorkoutExercise.new(exerciseId: 0, workoutId: 0)
        workoutExercise.id = 0

        var workoutSet = WorkoutSet.new(workoutExerciseId: 0)
        workoutSet.id = 1
        workoutSet.weight = 160
        workoutSet.repetitions = 5
        workoutSet.rpe = 10
        workoutSet.targetRepetitionsLower = 3
        workoutSet.targetRepetitionsUpper = 5
        workoutSet.isCompleted = true

        return (workoutSet, exercise.category)
    }
}
