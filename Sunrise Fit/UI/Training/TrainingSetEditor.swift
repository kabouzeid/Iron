//
//  TrainingSetEditor.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 29.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

private class TrainingSetViewModel: ObservableObject {
    var objectWillChange = PassthroughSubject<Void, Never>()
    private var cancellable: AnyCancellable?
    var trainingSet: TrainingSet
    var weightUnit: WeightUnit
    
    var weightInput: Double {
        set {
            trainingSet.weight = max(min(WeightUnit.convert(weight: newValue, from: weightUnit, to: .metric), TrainingSet.MAX_WEIGHT), 0)
        }
        get {
            WeightUnit.convert(weight: trainingSet.weight, from: .metric, to: weightUnit)
        }
    }
    var repetitionsInput: Double {
        set {
            trainingSet.repetitions = Int16(max(min(newValue, Double(TrainingSet.MAX_REPETITIONS)), 0))
        }
        get {
            Double(trainingSet.repetitions)
        }
    }
    
    init(trainingSet: TrainingSet, weightUnit: WeightUnit) {
        self.trainingSet = trainingSet
        self.weightUnit = weightUnit
        cancellable = trainingSet.objectWillChange.subscribe(objectWillChange)
    }
}

private enum KeyboardType {
    case weight
    case repetitions
    case none
}

struct TrainingSetEditor : View {
    @ObservedObject private var trainingSetViewModel: TrainingSetViewModel
    @State private var showMoreSheet = false
    @State private var showKeyboard: KeyboardType = .none
    @State private var alwaysShowDecimalSeparator = false
    @State private var minimumFractionDigits = 0

    var onDone: () -> Void = {}
    
    init(trainingSet: TrainingSet, weightUnit: WeightUnit, onDone: @escaping () -> Void = {}) {
        trainingSetViewModel = TrainingSetViewModel(trainingSet: trainingSet, weightUnit: weightUnit)
        self.onDone = onDone
    }

    private var weightNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = trainingSetViewModel.weightUnit.maximumFractionDigits
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.alwaysShowsDecimalSeparator = alwaysShowDecimalSeparator
        return formatter
    }
    
    private func textButton(label: Text, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                label
                    .padding(6)
                    .transition(.opacity)
                Spacer()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .foregroundColor(color)
        )
    }
    
    private var moreButton: some View {
        textButton(label: Text("More").foregroundColor(.secondary), color: Color(UIColor.systemGray4), action: { self.showMoreSheet = true })
    }
    
    private var doneButton: some View {
        textButton(label: Text(trainingSetViewModel.trainingSet.isCompleted ? "Ok" : "Complete Set").foregroundColor(.white), color: .accentColor, action: {
            self.onDone()
            if self.showKeyboard == .repetitions {
                self.showKeyboard = .weight
            }
        })
    }
    
    private var nextButton: some View {
        textButton(label: Text("Next").foregroundColor(.white), color: .accentColor, action: { self.showKeyboard = .repetitions })
    }
        
    private var hideKeyboardButton: some View {
        Button(action: {
            withAnimation {
                self.showKeyboard = .none
            }
        }) {
            HStack {
                Spacer()
                ZStack {
                    Text("More") // placeholder for button size
                        .foregroundColor(.clear)
                        .padding(6)
                    HStack {
                        Image(systemName: "keyboard")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.compact.down")
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .foregroundColor(Color(UIColor.systemGray4))
        )
    }
    
    private var buttons: some View {
        HStack(spacing: 0) {
            moreButton
                .padding()
            
            doneButton
                .padding()
        }
    }
    
    private var keyboardButtons: some View {
        HStack(spacing: 0) {
            hideKeyboardButton
                .padding()
            
            if showKeyboard == .weight {
                nextButton
                    .padding()
            } else {
                doneButton
                    .padding()
            }
        }
    }
    
    private var weightDragger: some View {
        Dragger(
            value: $trainingSetViewModel.weightInput,
            numberFormatter: weightNumberFormatter,
            unit: Text(trainingSetViewModel.weightUnit.abbrev),
            stepSize: trainingSetViewModel.weightUnit.barbellIncrement,
            minValue: 0,
            maxValue: WeightUnit.convert(weight: TrainingSet.MAX_WEIGHT, from: .metric, to: trainingSetViewModel.weightUnit),
            showCursor: showKeyboard == .weight,
            onDragStep: { _ in
                self.alwaysShowDecimalSeparator = false
                self.minimumFractionDigits = self.trainingSetViewModel.weightUnit.defaultFractionDigits
            },
            onDragCompleted: {
                self.alwaysShowDecimalSeparator = false
                self.minimumFractionDigits = 0
            },
            onTextTapped: {
                withAnimation {
                    self.showKeyboard = .weight
                }
            })
    }
    
    private var repetitionsDragger: some View {
        Dragger(
            value: $trainingSetViewModel.repetitionsInput,
            unit: Text("reps"),
            minValue: 0,
            maxValue: Double(TrainingSet.MAX_REPETITIONS),
            showCursor: showKeyboard == .repetitions,
            onTextTapped: {
                withAnimation {
                    self.showKeyboard = .repetitions
                }
        })
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                weightDragger
                repetitionsDragger
            }
            .padding([.top])
            
            if showKeyboard == .none {
                buttons
            } else {
                keyboardButtons
            }
            
            if showKeyboard == .weight {
                NumericKeyboard(
                    value: $trainingSetViewModel.weightInput,
                    alwaysShowDecimalSeparator: $alwaysShowDecimalSeparator,
                    minimumFractionDigits: $minimumFractionDigits,
                    maximumFractionDigits: trainingSetViewModel.weightUnit.maximumFractionDigits
                )
            } else if showKeyboard == .repetitions {
                NumericKeyboard(
                    value: $trainingSetViewModel.repetitionsInput,
                    alwaysShowDecimalSeparator: .constant(false),
                    minimumFractionDigits: .constant(0),
                    maximumFractionDigits: 0
                )
            }
        }
        .drawingGroup() // fixes visual bug with show/hide animation of this view
        .gesture(DragGesture()
            .onEnded({ drag in
                if drag.predictedEndTranslation.height > 100 {
                    withAnimation {
                        self.showKeyboard = .none
                    }
                }
            })
        )
        .sheet(isPresented: $showMoreSheet) {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Button("Close") {
                            self.showMoreSheet = false
                        }
                        Spacer()
                    }
                    Text(self.trainingSetViewModel.trainingSet.displayTitle(unit: self.trainingSetViewModel.weightUnit))
                        .font(.headline)
                }
                .padding()
                Divider()
                MoreView(trainingSet: self.trainingSetViewModel.trainingSet)
            }
        }
    }
}

private struct MoreView: View {
    @ObservedObject var trainingSet: TrainingSet
    
    // TODO: move these properties to TrainingSet in CoreData
    @State private var trainingSetComment: String = ""

    private func tagButton(tag: WorkoutSetTag) -> some View {
        Button(action: {
            if self.trainingSet.displayTag == tag {
                self.trainingSet.displayTag = nil
            } else {
                self.trainingSet.displayTag = tag
            }
        }) {
            HStack {
                Image(systemName: "circle.fill")
                    .imageScale(.small)
                    .foregroundColor(tag.color)
                Text(tag.title.capitalized)
                Spacer()
                if self.trainingSet.displayTag == tag {
                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func rpeButton(rpe: Double) -> some View {
        Button(action: {
            if self.trainingSet.displayRpe == rpe {
                self.trainingSet.displayRpe = nil
            } else {
                self.trainingSet.displayRpe = rpe
            }
        }) {
            HStack {
                Text(String(format: "%.1f", rpe))
                Text(RPE.title(rpe) ?? "")
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
                Spacer()
                if self.trainingSet.displayRpe == rpe {
                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        List {
            Section(header:
                HStack {
                    Text("Tag".uppercased())
                    Spacer()
                    Button(action: {
                        // TODO: show Tag help (in a Dialog)
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }) {
                ForEach(WorkoutSetTag.allCases, id: \.self) { tag in
                    self.tagButton(tag: tag)
                }
            }
            
            Section(header: Text("Comment".uppercased())) {
                TextField("Comment", text: $trainingSetComment, onEditingChanged: { _ in }, onCommit: {})
            }
            
            Section(header:
                HStack {
                    Text("RPE (Rating of Perceived Exertion)")
                    Spacer()
                    Button(action: {
                        // TODO: show RPE help (in a Dialog)
                    }) {
                        Image(systemName: "questionmark.circle")
                    }
                }) {
                ForEach(RPE.allowedValues.reversed(), id: \.self) { rpe in
                    self.rpeButton(rpe: rpe)
                }
            }
        }
        .listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct TrainingSetEditor_Previews : PreviewProvider {
    static var previews: some View {
        return Group {
            TrainingSetEditor(trainingSet: mockTrainingSet, weightUnit: .metric)
                .environment(\.managedObjectContext, mockManagedObjectContext)
                .previewDisplayName("Metric")
                .previewLayout(.sizeThatFits)
            
            TrainingSetEditor(trainingSet: mockTrainingSet, weightUnit: .imperial)
                .environment(\.managedObjectContext, mockManagedObjectContext)
                .previewDisplayName("Imperial")
                .previewLayout(.sizeThatFits)
            
            MoreView(trainingSet: mockTrainingSet)
                .environment(\.managedObjectContext, mockManagedObjectContext)
                .previewLayout(.sizeThatFits)
                .listStyle(GroupedListStyle())
        }
    }
}
#endif
