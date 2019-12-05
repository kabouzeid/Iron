//
//  StackedBarChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct BarStackEntry: Hashable {
    let color: Color
    let label: String
}

struct BarStack: Hashable {
    let entries: [BarStackEntry]
    let label: String // y
}

private struct BarStackView: View {
    let barStack: BarStack
    let entryHeight: CGFloat
    let spacing: CGFloat
    
    var body: some View {
        VStack(spacing: spacing) {
            ForEach(barStack.entries, id: \.self) { barStackEntry in
                RoundedRectangle(cornerRadius: 2)
                    .foregroundColor(barStackEntry.color)
                    .frame(height: self.entryHeight)
            }
            if barStack.entries.isEmpty {
                Rectangle()
                    .frame(height: 0)
                    .foregroundColor(.clear)
            }
        }
    }
}

struct BarStacksView: View {
    let barStacks: [BarStack]
    let spacing: CGFloat
    private let max: Int

    init(barStacks: [BarStack], spacing: CGFloat) {
        self.barStacks = barStacks
        self.spacing = spacing
        max = barStacks
            .map { $0.entries.count }
            .max() ?? 0
    }
    
    private func entryHeight(height: CGFloat) -> CGFloat {
        guard self.max > 0 else { return 0 }
        let spacingHeight = CGFloat(self.max - 1) * spacing
        let availableEntryHeight = (height - spacingHeight) / CGFloat(self.max)
        return availableEntryHeight
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom) {
                ForEach(self.barStacks, id: \.self) { barStack in
                    BarStackView(barStack: barStack, entryHeight: self.entryHeight(height: geometry.size.height), spacing: self.spacing)
                }
            }
        }
    }
}

struct BarLabelsView: View {
    let barStacks: [BarStack]
    let labelCount: Int
    
    private var threshold: Int {
        let threshold = barStacks.count / labelCount
        return threshold == 0 ? 1 : threshold
    }
    
    var body: some View {
        HStack {
            ForEach(0..<barStacks.count, id: \.self) { index in
                ZStack {
                    Rectangle() // just for correct spacing
                        .frame(height: 0)
                        .foregroundColor(.clear)
                    if index % self.threshold == 0 {
                        Text(self.barStacks[index].label)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct LegendView: View {
    let barStackEntries: [BarStackEntry]
    
    init(barStacks: [BarStack]) {
        barStackEntries = barStacks
            .map { $0.entries }
            .flatMap { $0 }
            .uniqed()
            .sorted { $0.label < $1.label }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(barStackEntries, id: \.self) { barStackEntry in
                VStack(alignment: .center) {
                    Circle()
                        .fill(barStackEntry.color)
                        .frame(width: 16, height: 16)
                    
                    Text(barStackEntry.label)
                        .lineLimit(1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .layoutPriority(10)
                    
                    HStack { Spacer() } // hack for using the full width
                }
            }
        }
    }
}

#if DEBUG
import WorkoutDataKit

struct BarChartView_Previews: PreviewProvider {
    static func randomBarStackEntries() -> [BarStackEntry] {
        var entries = [BarStackEntry]()
        for _ in 0...Int.random(in: 0...6) {
            var muscleGroup = "other"
            switch Int.random(in: 0...5) {
            case 0:
                muscleGroup = "abdominals"
            case 1:
                muscleGroup = "arms"
            case 2:
                muscleGroup = "shoulders"
            case 3:
                muscleGroup = "back"
            case 4:
                muscleGroup = "legs"
            case 5:
                muscleGroup = "chest"
            default:
                muscleGroup = "other"
            }
            entries.append(BarStackEntry(color: Exercise.colorFor(muscleGroup: muscleGroup), label: muscleGroup.capitalized))
        }
        return entries
    }
    
    static var activityData: [BarStack] = [
        BarStack(entries: randomBarStackEntries(), label: "1.7."),
        BarStack(entries: randomBarStackEntries(), label: "8.7."),
        BarStack(entries: randomBarStackEntries(), label: "15.7."),
        BarStack(entries: randomBarStackEntries(), label: "22.7."),
        BarStack(entries: randomBarStackEntries(), label: "29.7."),
        BarStack(entries: randomBarStackEntries(), label: "5.8."),
        BarStack(entries: randomBarStackEntries(), label: "12.8."),
        BarStack(entries: randomBarStackEntries(), label: "19.8.")
    ]
    
    static var previews: some View {
        VStack {
            BarStacksView(barStacks: activityData, spacing: 2)
                .frame(height: 200)
            BarLabelsView(barStacks: activityData, labelCount: activityData.count)
            LegendView(barStacks: activityData)
        }
        .padding([.leading, .trailing])
    }
}
#endif
