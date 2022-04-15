//
//  _WorkoutSetEditor.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 29.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

private enum KeyboardType {
    case weight
    case repetitions
    case none
}

struct _WorkoutSetEditor : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @ObservedObject var workoutSet: WorkoutSet
    var onDone: () -> Void = {}
    
    @State private var showHelpAlert = false
    
    @State private var showMoreSheet = false
    @State private var showKeyboard: KeyboardType = .none
    @State private var alwaysShowDecimalSeparator = false
    @State private var minimumFractionDigits = 0
    
    // used to immediatelly update the weight & rep texts so the keyboard feels more smooth
    @ObservedObject private var refresher = Refresher()
    
    private var workoutSetWeight: Binding<Double?> {
        Binding(
            get: {
                WeightUnit.convert(weight: self.workoutSet.weightValue, from: .metric, to: self.settingsStore.weightUnit)
            },
            set: { newValue in
                self.workoutSet.weightValue = max(min(WeightUnit.convert(weight: newValue ?? 0, from: self.settingsStore.weightUnit, to: .metric), WorkoutSet.MAX_WEIGHT), 0)
                self.refresher.refresh()
            }
        )
    }
    
    private var workoutSetRepetitions: Binding<Double?> {
        Binding(
            get: {
                Double(self.workoutSet.repetitionsValue)
            },
            set: { newValue in
                self.workoutSet.repetitionsValue = Int16(max(min(newValue ?? 0, Double(WorkoutSet.MAX_REPETITIONS)), 0))
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
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(color)
            )
        }
    }
    
    private var tagButton: some View {
        Button(action: {
            self.showMoreSheet = true
        }) {
            HStack(spacing: 0) {
                Image(systemName: "tag")
                    .padding(6)
            }
        }
    }
    
    private var doneButton: some View {
        textButton(label: Text(workoutSet.isCompleted ? "Ok" : "Complete Set").foregroundColor(.white), color: .accentColor, action: {
            self.onDone()
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
    
    private var weightStepSize: Double {
        // TODO: let the user configure this for barbell, dumbell and others
        (workoutSet.workoutExercise?.exercise(in: exerciseStore.exercises)?.type == .barbell) ? settingsStore.weightUnit.barbellIncrement : 1
    }
    
    private var weightDragger: some View {
        Dragger(
            value: workoutSetWeight,
            numberFormatter: weightNumberFormatter,
            unit: settingsStore.weightUnit.unit.symbol,
            stepSize: weightStepSize,
            minValue: 0,
            maxValue: WeightUnit.convert(weight: WorkoutSet.MAX_WEIGHT, from: .metric, to: settingsStore.weightUnit),
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
            value: workoutSetRepetitions,
            unit: "reps",
            minValue: 0,
            maxValue: Double(WorkoutSet.MAX_REPETITIONS),
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
    
    private var moreSheet: some View {
        NavigationView {
            MoreView(workoutSet: workoutSet)
                .navigationBarTitle(Text(workoutSet.displayTitle(weightUnit: settingsStore.weightUnit)), displayMode: .inline)
                .navigationBarItems(leading:
                    Button("Close") {
                        self.showMoreSheet = false
                    }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var keyboard: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                NumericKeyboard(
                    value: self.showKeyboard == .weight ? self.workoutSetWeight : self.workoutSetRepetitions,
                    alwaysShowDecimalSeparator: self.showKeyboard == .weight ? self.$alwaysShowDecimalSeparator : .constant(false),
                    minimumFractionDigits: self.showKeyboard == .weight ? self.$minimumFractionDigits : .constant(0),
                    maximumFractionDigits: self.showKeyboard == .weight ? self.settingsStore.weightUnit.maximumFractionDigits : 0
                )
                VStack(spacing: 0) {
                    NumericKeyboard.imageActionKeyboardButton(label: Image(systemName: "keyboard.chevron.compact.down"), width: geometry.size.width / 4) {
                        withAnimation {
                            self.showKeyboard = .none
                        }
                    }
                    
                    NumericKeyboard.imageActionKeyboardButton(label: Image(systemName: "questionmark"), width: geometry.size.width / 4) {
                        self.showHelpAlert = true
                    }
                    
                    NumericKeyboard.imageActionKeyboardButton(label: Image(systemName: "tag"), width: geometry.size.width / 4) {
                        self.showMoreSheet = true
                    }
                    
                    Button(action: {
                        NumericKeyboard.playButtonSound()
                        if self.showKeyboard == .weight {
                            self.showKeyboard = .repetitions
                        } else if self.showKeyboard == .repetitions {
                            self.onDone()
                            self.showKeyboard = .weight
                        }
                    }) {
                        Image(systemName: self.showKeyboard == .weight ? "arrow.right" : "checkmark")
                            .padding()
                            .foregroundColor(.white)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .foregroundColor(Color.accentColor)
                        )
                            .frame(width: geometry.size.width / 4, height: geometry.size.height / 4)
                    }
                }
                .frame(width: geometry.size.width / 4)
            }
        }.frame(height: NumericKeyboard.HEIGHT)
    }
    
    var body: some View {
        VStack { /// no spacing to the keyboard
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    /**
                     NOTE: the draggers shouldn't be too low because
                     1. the thumb would be in an uncomfortable position
                     2. one easily triggers the reachability accessibilty on devices without a home button
                     */
                    weightDragger
                    Divider().frame(height: 44)
//                    Text("×").foregroundColor(Color(.quaternaryLabel))
                    repetitionsDragger
                }
                
                if showKeyboard == .none {
                    HStack(spacing: 16) {
                        tagButton
                        doneButton
                    }
                    .padding(.bottom, 8) /// pushes the draggers up and makes the buttons look more centered
                }
            }.padding([.leading, .trailing])
            
            if showKeyboard != .none {
                keyboard
            }
        }
        .padding([.top, .bottom])
//        .drawingGroup() /// fixes visual bug with show/hide animation of this view
        .gesture(DragGesture()
            .onEnded({ drag in
                let width = drag.predictedEndTranslation.width
                let height = drag.predictedEndTranslation.height
                
                if abs(height) > abs(width) {
                    if height > 200 {
                        withAnimation {
                            self.showKeyboard = .none
                        }
                    }
                } else {
                    if width > 200 {
                        withAnimation {
                            self.showKeyboard = .repetitions
                        }
                    } else if width < 200 {
                        withAnimation {
                            self.showKeyboard = .weight
                        }
                    }
                }
            })
        )
        .sheet(isPresented: $showMoreSheet) { self.moreSheet }
        .alert(isPresented: $showHelpAlert) { Alert(title: Text("You can also drag ☰ up and down to adjust the values.")) }
    }
}

private struct MoreView: View {
    @ObservedObject var workoutSet: WorkoutSet
    
    @State private var activeAlert: AlertType?
    
    private enum AlertType: Identifiable {
        case tagInfo
        case rpeInfo
        
        var id: Self { self }
    }
    
    private func alertFor(type: AlertType) -> Alert {
        switch type {
        case .tagInfo:
            return Alert(title: Text("Mark a set as Failure if you've tried to do more reps but failed."))
        case .rpeInfo:
            return Alert(title: Text("The rating of perceived exertion (RPE) is a way to determine and regulate your workout intensity."))
        }
    }
    
    @State private var workoutSetCommentInput: String? // cannot use ValueHolder here, since it would be recreated on changes
    private var workoutSetComment: Binding<String> {
        Binding(
            get: {
                self.workoutSetCommentInput ?? self.workoutSet.comment ?? ""
            },
            set: { newValue in
                self.workoutSetCommentInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutSetCommentInput() {
        guard let newValue = workoutSetCommentInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutSetCommentInput = newValue
        workoutSet.comment = newValue.isEmpty ? nil : newValue
        workoutSet.managedObjectContext?.saveOrCrash()
    }

    private func tagButton(tag: WorkoutSetTag) -> some View {
        Button(action: {
            if self.workoutSet.tagValue == tag {
                self.workoutSet.tagValue = nil
            } else {
                self.workoutSet.tagValue = tag
            }
        }) {
            HStack {
                Image(systemName: "circle.fill")
                    .imageScale(.small)
                    .foregroundColor(tag.color)
                Text(tag.title.capitalized)
                Spacer()
                if self.workoutSet.tagValue == tag {
                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                }
            }.background(Color.fakeClear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func rpeButton(rpe: Double) -> some View {
        Button(action: {
            if self.workoutSet.rpeValue == rpe {
                self.workoutSet.rpeValue = nil
            } else {
                self.workoutSet.rpeValue = rpe
            }
        }) {
            HStack {
                Text(String(format: "%.1f", rpe))
                Text(RPE.title(rpe) ?? "")
                    .lineLimit(nil)
                    .foregroundColor(.secondary)
                Spacer()
                if self.workoutSet.rpeValue == rpe {
                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                }
            }.background(Color.fakeClear)
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
                        self.activeAlert = .tagInfo
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.accentColor)
                    }
                }) {
                ForEach(WorkoutSetTag.allCases, id: \.self) { tag in
                    self.tagButton(tag: tag)
                }
            }
            
            Section(header: Text("Comment".uppercased())) {
                TextField("Comment", text: workoutSetComment, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutSetCommentInput()
                    }
                })
            }
            
            Section(header:
                HStack {
                    Text("RPE (Rating of Perceived Exertion)")
                    Spacer()
                    Button(action: {
                        self.activeAlert = .rpeInfo
                    }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.accentColor)
                    }
                }) {
                ForEach(RPE.allowedValues.reversed(), id: \.self) { rpe in
                    self.rpeButton(rpe: rpe)
                }
            }
        }
        .listStyleCompat_InsetGroupedListStyle()
        .alert(item: $activeAlert) { self.alertFor(type: $0) }
    }
}

#if DEBUG
struct _WorkoutSetEditor_Previews : PreviewProvider {
    static var previews: some View {
        return Group {
            _WorkoutSetEditor(workoutSet: MockWorkoutData.metricRandom.workoutSet)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewDisplayName("Metric")
                .previewLayout(.sizeThatFits)
            
            _WorkoutSetEditor(workoutSet: MockWorkoutData.imperialRandom.workoutSet)
                .mockEnvironment(weightUnit: .imperial, isPro: true)
                .previewDisplayName("Imperial")
                .previewLayout(.sizeThatFits)
            
            MoreView(workoutSet: MockWorkoutData.metricRandom.workoutSet)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
                .listStyle(GroupedListStyle())
        }
    }
}
#endif
