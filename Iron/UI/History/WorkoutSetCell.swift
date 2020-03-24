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
            
//            if colorMode == .selected || isPlaceholder {
                workoutSet.minTargetRepetitionsValue.map { plannedRepetitionsMin in
                    workoutSet.maxTargetRepetitionsValue.map { plannedRepetitionsMax in
                        Text("\(plannedRepetitionsMin == plannedRepetitionsMax ? "\(plannedRepetitionsMin)" : "\(plannedRepetitionsMin)-\(plannedRepetitionsMax)") reps")
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
//            }
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
    static var previews: some View {
        WorkoutSetCell(workoutSet: MockWorkoutData.metricRandom.workoutSet, index: 1)
            .mockEnvironment(weightUnit: .metric, isPro: true)
            .previewLayout(.sizeThatFits)
    }
}
#endif
