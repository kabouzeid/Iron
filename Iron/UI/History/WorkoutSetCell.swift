//
//  WorkoutSetCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 28.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutSetCell: View {
    @EnvironmentObject var settingsStore: SettingsStore

    @ObservedObject var workoutSet: WorkoutSet
    let index: Int
    var colorMode: ColorMode = .activated
    var titleType: TitleType = .weightAndReps
    
    enum ColorMode {
        case activated
        case deactivated
        case disabled
    }
    
    enum TitleType {
        case weightAndReps
        case placeholder
        case placeholderWeightAndReps
    }
    
    private func title(textMode: TitleType) -> String {
        switch textMode {
        case .weightAndReps:
            return workoutSet.displayTitle(unit: settingsStore.weightUnit)
        case .placeholder:
            return "Set"
        case .placeholderWeightAndReps:
            return title(textMode: .placeholder) + " (\(title(textMode: .weightAndReps)))"
        }
    }
    
    private func rpe(rpe: Double) -> some View {
        VStack {
            Group {
                Text(String(format: "%.1f", rpe))
                Text("RPE")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title(textMode: titleType))
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(colorMode == .activated ? .primary : .secondary)
                workoutSet.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            workoutSet.displayRpe.map {
                self.rpe(rpe: $0)
            }
            if workoutSet.isPersonalRecord ?? false {
                // TODO: replace with a trophy symbol
                Image(systemName: "star.circle.fill")
                    .foregroundColor(colorMode == .disabled ? .secondary : .yellow)
            }
            Text("\(index)")
                .font(Font.body.monospacedDigit())
                .foregroundColor(workoutSet.displayTag != nil ? .clear : .secondary)
                .background(
                    Group {
                        workoutSet.displayTag.map {
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
