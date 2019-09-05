//
//  TrainingSetEditor.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 29.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

private enum KeyboardType {
    case weight
    case repetitions
    case none
}

struct TrainingSetEditor : View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    @ObservedObject var trainingSet: TrainingSet
    var onDone: () -> Void = {}
    
    @State private var showMoreSheet = false
    @State private var showKeyboard: KeyboardType = .none
    @State private var alwaysShowDecimalSeparator = false
    @State private var minimumFractionDigits = 0
    
    // used to immediatelly update the weight & rep texts so the keyboard feels more smooth
    @ObservedObject private var refresher = Refresher()
    
    private var trainingSetWeight: Binding<Double> {
        Binding(
            get: {
                WeightUnit.convert(weight: self.trainingSet.weight, from: .metric, to: self.settingsStore.weightUnit)
            },
            set: { newValue in
                self.trainingSet.weight = max(min(WeightUnit.convert(weight: newValue, from: self.settingsStore.weightUnit, to: .metric), TrainingSet.MAX_WEIGHT), 0)
                self.refresher.refresh()
            }
        )
    }
    
    private var trainingSetRepetitions: Binding<Double> {
        Binding(
            get: {
                Double(self.trainingSet.repetitions)
            },
            set: { newValue in
                self.trainingSet.repetitions = Int16(max(min(newValue, Double(TrainingSet.MAX_REPETITIONS)), 0))
                self.refresher.refresh()
            }
        )
    }

    private var weightNumberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = settingsStore.weightUnit.maximumFractionDigits
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
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(color)
            )
        }
    }
    
    private var moreButton: some View {
        textButton(label: Text("More").foregroundColor(.secondary), color: Color(UIColor.systemFill), action: { self.showMoreSheet = true })
    }
    
    private var doneButton: some View {
        textButton(label: Text(trainingSet.isCompleted ? "Ok" : "Complete Set").foregroundColor(.white), color: .accentColor, action: {
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
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(Color(UIColor.systemFill))
            )
        }
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
    
    private var weightStepSize: Double {
        // TODO: let the user configure this for barbell, dumbell and others
        (trainingSet.trainingExercise?.exercise?.isBarbellBased ?? false) ? settingsStore.weightUnit.barbellIncrement : 1
    }
    
    private var weightDragger: some View {
        Dragger(
            value: trainingSetWeight,
            numberFormatter: weightNumberFormatter,
            unit: settingsStore.weightUnit.abbrev,
            stepSize: weightStepSize,
            minValue: 0,
            maxValue: WeightUnit.convert(weight: TrainingSet.MAX_WEIGHT, from: .metric, to: settingsStore.weightUnit),
            showCursor: showKeyboard == .weight,
            onDragStep: { _ in
                self.alwaysShowDecimalSeparator = false
                self.minimumFractionDigits = self.settingsStore.weightUnit.defaultFractionDigits
            },
            onDragCompleted: {
                self.alwaysShowDecimalSeparator = false
                self.minimumFractionDigits = 0
            },
            onTextTapped: {
                if self.showKeyboard == .none {
                    withAnimation {
                        self.showKeyboard = .weight
                    }
                } else {
                    self.showKeyboard = .weight
                }
            })
    }
    
    private var repetitionsDragger: some View {
        Dragger(
            value: trainingSetRepetitions,
            unit: "reps",
            minValue: 0,
            maxValue: Double(TrainingSet.MAX_REPETITIONS),
            showCursor: showKeyboard == .repetitions,
            onTextTapped: {
                if self.showKeyboard == .none {
                    withAnimation {
                        self.showKeyboard = .repetitions
                    }
                } else {
                    self.showKeyboard = .repetitions
                }
        })
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                weightDragger
                    .padding([.leading, .trailing])
                repetitionsDragger
                    .padding([.leading, .trailing])
            }
            .padding([.top])
            
            if showKeyboard == .none {
                buttons
            } else {
                keyboardButtons
            }
            
            if showKeyboard == .weight {
                NumericKeyboard(
                    value: trainingSetWeight,
                    alwaysShowDecimalSeparator: $alwaysShowDecimalSeparator,
                    minimumFractionDigits: $minimumFractionDigits,
                    maximumFractionDigits: settingsStore.weightUnit.maximumFractionDigits
                )
            } else if showKeyboard == .repetitions {
                NumericKeyboard(
                    value: trainingSetRepetitions,
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
                    Text(self.trainingSet.displayTitle(unit: self.settingsStore.weightUnit))
                        .font(.headline)
                }
                .padding()
                Divider()
                MoreView(trainingSet: self.trainingSet)
            }
        }
    }
}

private struct MoreView: View {
    @ObservedObject var trainingSet: TrainingSet

    // bridges empty and whitespace values to nil
    private var trainingSetComment: Binding<String> {
        Binding(
            get: {
                self.trainingSet.comment ?? ""
            },
            set: { newValue in
                self.trainingSet.comment = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue
            }
        )
    }

    private func tagButton(tag: TrainingSetTag) -> some View {
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
                ForEach(TrainingSetTag.allCases, id: \.self) { tag in
                    self.tagButton(tag: tag)
                }
            }
            
            Section(header: Text("Comment".uppercased())) {
                TextField("Comment", text: trainingSetComment)
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
            TrainingSetEditor(trainingSet: mockTrainingSet)
                .environment(\.managedObjectContext, mockManagedObjectContext)
                .environmentObject(mockSettingsStoreMetric)
                .previewDisplayName("Metric")
                .previewLayout(.sizeThatFits)
            
            TrainingSetEditor(trainingSet: mockTrainingSet)
                .environment(\.managedObjectContext, mockManagedObjectContext)
                .environmentObject(mockSettingsStoreImperial)
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
