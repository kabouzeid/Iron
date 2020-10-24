//
//  BarChartView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct Bar: Hashable {
    let value: Int
    let label: String // y
    
    var barColor: Color?
    var labelColor: Color?
}

struct BarChartView: View {
    let bars: [Bar]
    let maxValue: Int
    let showGrid: Bool
    let showLabels: Bool
    
    init(bars: [Bar], showGrid: Bool = true, showLabels: Bool = true, minimumMaxValue: Int = 0) {
        assert(bars.allSatisfy({ $0.value >= 0 }))
        self.bars = bars
        self.showGrid = showGrid
        self.showLabels = showLabels
        self.maxValue = max(bars.map { $0.value }.max() ?? 0, minimumMaxValue)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if showGrid {
                    BarChartGridView()
                }
                BarView(bars: bars, maxValue: maxValue)
                    .padding(.trailing)
                
                if showGrid {
                    Text(String(maxValue))
                        .padding(2)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)

            if showLabels {
                BarLabelsView(bars: bars, labelCount: bars.count)
                    .padding(.trailing)
            }
        }
    }
}

private struct BarView: View {
    let bars: [Bar]
    let maxValue: Int

    var body: some View {
        GeometryReader { geometry in
            HStack {
                ForEach(bars, id: \.self) { bar in
                    ZStack(alignment: .bottom) {
                        Rectangle().frame(height: geometry.size.height).hidden() // force fill width + height
                        if maxValue > 0 { // should always be the case
                            Rectangle()
                                .foregroundColor(bar.barColor ?? .accentColor)
                                .frame(width: 20, height: (CGFloat(bar.value) / CGFloat(maxValue)) * geometry.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
            }
        }
    }
}

private struct BarLabelsView: View {
    let bars: [Bar]
    let labelCount: Int
    
    private var threshold: Int {
        let threshold = bars.count / labelCount
        return threshold == 0 ? 1 : threshold
    }
    
    var body: some View {
        HStack {
            ForEach(bars.enumerated().map { ($0.0, $0.1) }, id: \.1.self) { index, bar in
                ZStack {
                    Rectangle().frame(height: 0).hidden()
                    
                    if index % self.threshold == 0 {
                        Text(bar.label)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(bar.labelColor ?? .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            }
        }
    }
}

private struct BarChartGridView: View {
    var body: some View {
        BarChartGrid()
            .stroke(
                Color.secondary,
                style: StrokeStyle(
                    lineWidth: 1,
                    lineCap: .round,
                    lineJoin: .round,
                    miterLimit: 0,
                    dash: [1, 8],
                    dashPhase: 0
                )
        )
    }
    
    private struct BarChartGrid: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: rect.width, y: 0))

                path.move(to: CGPoint(x: 0, y: rect.height))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height))
                
                path.move(to: CGPoint(x: 0, y: rect.height / 2))
                path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            }
        }
    }
}

#if DEBUG
import WorkoutDataKit

struct BarChartView_Previews: PreviewProvider {
    static let bars: [Bar] = [
        Bar(value: Int.random(in: 0..<7), label: "1.7."),
        Bar(value: Int.random(in: 0..<7), label: "8.7."),
        Bar(value: Int.random(in: 0..<7), label: "15.7."),
        Bar(value: Int.random(in: 0..<7), label: "22.7."),
        Bar(value: Int.random(in: 0..<7), label: "29.7."),
        Bar(value: Int.random(in: 0..<7), label: "5.8."),
        Bar(value: Int.random(in: 0..<7), label: "12.8.")
    ]
    
    static var previews: some View {
        Group {
            BarChartView(bars: bars)
                .frame(height: 200)
                .previewLayout(.sizeThatFits)
            BarChartView(bars: bars, showGrid: false)
                .frame(height: 200)
                .previewLayout(.sizeThatFits)
            BarChartView(bars: bars, showLabels: false)
                .frame(height: 200)
                .previewLayout(.sizeThatFits)
            BarChartView(bars: bars, minimumMaxValue: 10)
                .frame(height: 200)
                .previewLayout(.sizeThatFits)
        }
    }
}
#endif
