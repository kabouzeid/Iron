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
    var weightInput: Double {
        didSet {
            trainingSet.weight = self.weightInput
        }
    }
    var repetitionsInput: Double {
        didSet {
            trainingSet.repetitions = Int16(self.repetitionsInput)
        }
    }
    
    init(trainingSet: TrainingSet) {
        self.trainingSet = trainingSet
        weightInput = trainingSet.weight
        repetitionsInput = Double(trainingSet.repetitions)
    }
}

struct TrainingSetEditor : View {
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore
    @ObjectBinding private var trainingSetViewModel: TrainingSetViewModel

    var weightNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 1
        return formatter
    }
    
    init(trainingSet: TrainingSet) {
        trainingSetViewModel = TrainingSetViewModel(trainingSet: trainingSet)
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Dragger(value: $trainingSetViewModel.weightInput, numberFormatter: weightNumberFormatter, unit: Text("kg"), stepSize: 2.5, minValue: 0)
                Dragger(value: $trainingSetViewModel.repetitionsInput, unit: Text("reps"), minValue: 1)
                }
                .padding([.top])
            HStack(spacing: 0) {
                Button(action: {
                    // TODO
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
                        .foregroundColor(.init(white: 0.8))
                        .cornerRadius(4))
                    .padding()
                Button(action: {
                    // TODO
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
            TrainingSetEditor(trainingSet: mockTrainingSet)
                .environmentObject(mockTrainingsDataStore)
                .previewLayout(.sizeThatFits)
        }
    }
}
#endif
