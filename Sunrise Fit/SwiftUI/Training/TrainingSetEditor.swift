//
//  TrainingSetEditor.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 29.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

private class TrainingSetViewModel : BindableObject {
    var willChange = PassthroughSubject<Void, Never>()
    
    var trainingSet: TrainingSet
    var weightUnit: WeightUnit
    var weightInput: Double {
        set {
            trainingSet.weight = min(WeightUnit.convert(weight: newValue, from: weightUnit, to: .metric), TrainingSet.MAX_WEIGHT)
        }
        get {
            WeightUnit.convert(weight: trainingSet.weight, from: .metric, to: weightUnit)
        }
    }
    var repetitionsInput: Double {
        set {
            trainingSet.repetitions = Int16(min(newValue, Double(TrainingSet.MAX_REPETITIONS)))
        }
        get {
            Double(trainingSet.repetitions)
        }
    }
    
    init(trainingSet: TrainingSet, weightUnit: WeightUnit) {
        self.trainingSet = trainingSet
        self.weightUnit = weightUnit
    }
}

struct TrainingSetEditor : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    @ObjectBinding private var trainingSetViewModel: TrainingSetViewModel
    @State private var alwaysShowDecimalSeparator = false
    @State private var minimumFractionDigits = 0
    private var maximumFractionDigits = 3
    
    var onComment: () -> Void
    var onComplete: () -> Void

    var weightNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.alwaysShowsDecimalSeparator = alwaysShowDecimalSeparator
        return formatter
    }
    
    init(trainingSet: TrainingSet, weightUnit: WeightUnit, onComment: @escaping () -> Void = {}, onComplete: @escaping () -> Void = {}) {
        trainingSetViewModel = TrainingSetViewModel(trainingSet: trainingSet, weightUnit: weightUnit)
        self.onComment = onComment
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Dragger(value: $trainingSetViewModel.weightInput, numberFormatter: weightNumberFormatter, unit: Text(trainingSetViewModel.weightUnit.abbrev), stepSize: trainingSetViewModel.weightUnit.barbellIncrement, minValue: 0, maxValue: WeightUnit.convert(weight: TrainingSet.MAX_WEIGHT, from: .metric, to: trainingSetViewModel.weightUnit)) { _ in
                    self.alwaysShowDecimalSeparator = false
                    self.minimumFractionDigits = self.trainingSetViewModel.weightUnit.defaultFractionDigits
                }
                Dragger(value: $trainingSetViewModel.repetitionsInput, unit: Text("reps"), minValue: 1, maxValue: Double(TrainingSet.MAX_REPETITIONS))
                }
                .padding([.top])
            HStack(spacing: 0) {
                Button(action: {
                    self.onComment()
                }) {
                    HStack {
                        Spacer()
                        Text("Comment")
                            .foregroundColor(.secondary)
                            .padding(6)
                        Spacer()
                    }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .foregroundColor(UIColor.systemGray4.swiftUIColor)
                    )
                    .padding()
                Button(action: {
                    self.onComplete()
                }) {
                    HStack {
                        Spacer()
                        Text("Complete Set")
                            .foregroundColor(.white)
                            .padding(6)
                        Spacer()
                    }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .foregroundColor(.accentColor)
                    )
                    .padding()
            }
//            NumericKeyboard(value: $trainingSetViewModel.weightInput, alwaysShowDecimalSeparator: $alwaysShowDecimalSeparator, minimumFractionDigits: $minimumFractionDigits, maximumFractionDigits: maximumFractionDigits)
//            NumericKeyboard(value: $trainingSetViewModel.repetitionsInput, alwaysShowDecimalSeparator: .constant(false), minimumFractionDigits: .constant(0), maximumFractionDigits: 0)
        }
        .drawingGroup() // fixes visual bug with show/hide animation of this view
    }
}

#if DEBUG
struct TrainingSetEditor_Previews : PreviewProvider {
    static var previews: some View {
        return Group {
            TrainingSetEditor(trainingSet: mockTrainingSet, weightUnit: .metric)
                .environmentObject(mockTrainingsDataStore)
                .previewDisplayName("Metric")
                .previewLayout(.sizeThatFits)
            
            TrainingSetEditor(trainingSet: mockTrainingSet, weightUnit: .imperial)
                .environmentObject(mockTrainingsDataStore)
                .previewDisplayName("Imperial")
                .previewLayout(.sizeThatFits)
        }
    }
}
#endif
