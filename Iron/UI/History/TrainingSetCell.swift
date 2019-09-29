//
//  TrainingSetCell.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 28.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TrainingSetCell: View {
    @EnvironmentObject var settingsStore: SettingsStore

    @ObservedObject var trainingSet: TrainingSet
    let index: Int
    var colorMode: ColorMode = .activated
    var textMode: TextMode = .weightAndReps
    
    enum ColorMode {
        case activated
        case deactivated
        case disabled
    }
    
    enum TextMode {
        case weightAndReps
        case placeholder
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
                Text(textMode == .weightAndReps ? trainingSet.displayTitle(unit: settingsStore.weightUnit) : "Set \(index)")
                    .font(Font.body.monospacedDigit())
                    .foregroundColor(colorMode == .activated ? .primary : .secondary)
                trainingSet.comment.map {
                    Text($0.enquoted)
                        .lineLimit(1)
                        .font(Font.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            trainingSet.displayRpe.map {
                self.rpe(rpe: $0)
            }
            if trainingSet.isPersonalRecord ?? false {
                // TODO: replace with a trophy symbol
                Image(systemName: "star.circle.fill")
                    .foregroundColor(colorMode == .disabled ? .secondary : .yellow)
            }
            Text("\(index)")
                .font(Font.body.monospacedDigit())
                .foregroundColor(trainingSet.displayTag != nil ? .clear : .secondary)
                .background(
                    Group {
                        trainingSet.displayTag.map {
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
struct TrainingSetCell_Previews: PreviewProvider {
    static var previews: some View {
        TrainingSetCell(trainingSet: mockTrainingSet, index: 1)
            .environmentObject(SettingsStore.mockMetric)
            .previewLayout(.sizeThatFits)
    }
}
#endif
