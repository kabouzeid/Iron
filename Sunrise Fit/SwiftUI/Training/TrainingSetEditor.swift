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
    var didChange = PassthroughSubject<Void, Never>()
    
    var trainingSet: TrainingSet
    var weightUnit: WeightUnit
    var weightInput: Double {
        set {
            trainingSet.weight = WeightUnit.convert(weight: newValue, from: weightUnit, to: .metric)
        }
        get {
            WeightUnit.convert(weight: trainingSet.weight, from: .metric, to: weightUnit)
        }
    }
    var repetitionsInput: Double {
        set {
            trainingSet.repetitions = Int16(newValue)
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
    
    var onComment: () -> Void
    var onComplete: () -> Void

    var weightNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 1
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
                Dragger(value: $trainingSetViewModel.weightInput, numberFormatter: weightNumberFormatter, unit: Text(trainingSetViewModel.weightUnit.abbrev), stepSize: trainingSetViewModel.weightUnit.barbellIncrement, minValue: 0)
                Dragger(value: $trainingSetViewModel.repetitionsInput, unit: Text("reps"), minValue: 1)
                }
                .padding([.top])
            HStack(spacing: 0) {
                Button(action: {
                    self.onComment()
                }) {
                    HStack {
                        Spacer()
                        Text("Comment")
                            .color(.secondary)
                            .padding(6)
                        Spacer()
                    }
                    }
                    .background(Rectangle()
                        .foregroundColor(UIColor.systemGray4.swiftUIColor)
                        .cornerRadius(4))
                    .padding()
                Button(action: {
                    self.onComplete()
                }) {
                    HStack {
                        Spacer()
                        Text("Complete Set")
                            .color(.white)
                            .padding(6)
                        Spacer()
                    }
                    }
                    .background(Rectangle()
                        .foregroundColor(.accentColor)
                        .cornerRadius(4))
                    .padding()
            }
        }
    }
}

#if DEBUG
struct TrainingSetEditor_Previews : PreviewProvider {
    static var previews: some View {
        return Group {
            TrainingSetEditor(trainingSet: mockTrainingSet, weightUnit: .metric)
                .environmentObject(mockTrainingsDataStore)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Metric")
            
            TrainingSetEditor(trainingSet: mockTrainingSet, weightUnit: .imperial)
                .environmentObject(mockTrainingsDataStore)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Imperial")
        }
    }
}
#endif
