//
//  WorkoutSetCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 28.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutSetCell: View {
    @EnvironmentObject var settingsStore: SettingsStore

    @ObservedObject var workoutSet: WorkoutSet
    let index: Int
    var colorMode: ColorMode = .activated
    var isPlaceholder = false
    var showCompleted = false
    var showUpNextIndicator = false
    
    enum ColorMode {
        case selected
        case activated
        case deactivated
        case disabled
    }
    
    private func titleView(isPlaceholder: Bool, colorMode: ColorMode) -> some View {
        HStack {
            if isPlaceholder {
                Text("Set")
                    .foregroundColor(.secondary)
            } else {
                Text(workoutSet.displayTitle(weightUnit: settingsStore.weightUnit))
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(colorMode == .selected ? .accentColor : colorMode == .activated ? .primary : .secondary)
            }
            
            TargetRepetitionsView(
                minRepetitions: workoutSet.minTargetRepetitionsValue,
                maxRepetitions: workoutSet.maxTargetRepetitionsValue
            )
            .foregroundColor(Color(.tertiaryLabel))
            .padding(.leading, 8)
        }
    }
    
    private func rpe(rpe: Double) -> some View {
        Text("RPE \(String(format: "%.1f", rpe))")
            .font(Font.caption.monospacedDigit())
            .foregroundColor(.secondary)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder()
                    .foregroundColor(Color(.systemFill))
                
        )
    }
    
    var body: some View {
        HStack {
            if showUpNextIndicator {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(.accentColor)
            } else if showCompleted && workoutSet.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(colorMode == .disabled ? .secondary : .green)
            }
            
            VStack(alignment: .leading) {
                titleView(isPlaceholder: isPlaceholder, colorMode: colorMode)
                
                workoutSet.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            workoutSet.rpeValue.map {
                self.rpe(rpe: $0)
            }
            if workoutSet.isPersonalRecord ?? false {
                // TODO: replace with a trophy symbol
                Image(systemName: "star.circle.fill")
                    .foregroundColor(colorMode == .disabled ? .secondary : .yellow)
            }

            Text("\(index)")
                .font(Font.body.monospacedDigit())
                .foregroundColor(workoutSet.tagValue != nil ? .clear : .secondary)
                .background(
                    Group {
                        workoutSet.tagValue.map {
                            Text($0.title.first!.uppercased())
                                .fontWeight(.semibold)
                                .foregroundColor($0.color)
                                .fixedSize()
                        }
                    }
                )
        }
    }
}

#if DEBUG
struct WorkoutSetCell_Previews: PreviewProvider {
    static var workoutSet1: WorkoutSet = {
        let set = WorkoutSet(context: MockWorkoutData.metric.context)
        set.weightValue = 82.5
        set.repetitionsValue = 5
        return set
    }()
    
    static var workoutSet2: WorkoutSet = {
        let set = WorkoutSet(context: MockWorkoutData.metric.context)
        set.weightValue = 82.5
        set.repetitionsValue = 5
        set.tagValue = .dropSet
        set.comment = "This is a comment"
        return set
    }()
    
    static var workoutSet3: WorkoutSet = {
        let set = WorkoutSet(context: MockWorkoutData.metric.context)
        set.weightValue = 82.5
        set.repetitionsValue = 5
        set.minTargetRepetitionsValue = 8
        set.maxTargetRepetitionsValue = 12
        return set
    }()
    
    static var workoutSet4: WorkoutSet = {
        let set = WorkoutSet(context: MockWorkoutData.metric.context)
        set.weightValue = 82.5
        set.repetitionsValue = 5
        set.maxTargetRepetitionsValue = 12
        return set
    }()
    
    static var workoutSet5: WorkoutSet = {
        let set = WorkoutSet(context: MockWorkoutData.metric.context)
        set.weightValue = 82.5
        set.repetitionsValue = 5
        set.minTargetRepetitionsValue = 8
        return set
    }()
    
    static var workoutSet6: WorkoutSet = {
        let set = WorkoutSet(context: MockWorkoutData.metric.context)
        set.weightValue = 82.5
        set.repetitionsValue = 5
        set.isCompleted = true
        return set
    }()
    
    static var previews: some View {
        List {
            WorkoutSetCell(workoutSet: workoutSet1, index: 1)
            WorkoutSetCell(workoutSet: workoutSet2, index: 2)
            WorkoutSetCell(workoutSet: workoutSet3, index: 3)
            WorkoutSetCell(workoutSet: workoutSet4, index: 4)
            WorkoutSetCell(workoutSet: workoutSet5, index: 5)
            
            Section {
                WorkoutSetCell(workoutSet: workoutSet6, index: 1, showCompleted: true)
                WorkoutSetCell(workoutSet: workoutSet6, index: 2, colorMode: .selected, showCompleted: true)
                WorkoutSetCell(workoutSet: workoutSet6, index: 3, showUpNextIndicator: true)
                WorkoutSetCell(workoutSet: workoutSet3, index: 4, isPlaceholder: true)
                WorkoutSetCell(workoutSet: workoutSet1, index: 5, isPlaceholder: true)
            }
        }
        .listStyle(GroupedListStyle())
        .mockEnvironment(weightUnit: .metric, isPro: true)
    }
}
#endif
