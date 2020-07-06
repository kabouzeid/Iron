//
//  WorkoutRoutineSetEditor.swift
//  Iron
//
//  Created by Karim Abou Zeid on 21.03.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit

struct WorkoutRoutineSetEditor: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var exerciseStore: ExerciseStore
    
    @State private var showKeyboard: KeyboardType = .none {
        didSet {
            if showKeyboard == .none {
                self.overwriteRepetitionsMin = nil
                self.overwriteRepetitionsMax = nil
            }
        }
    }
    private enum KeyboardType {
        case repetitionsMin
        case repetitionsMax
        case none
    }
    
    @State private var showMoreSheet = false
    
    @State private var showHelpAlert = false
    
    @ObservedObject var workoutRoutineSet: WorkoutRoutineSet
    
    @ObservedObject private var refresher = Refresher()
    
    @Binding var overwriteRepetitionsMin: Int16? // should be set to nil by the parent view when the selected workoutRoutineSet changes
    @Binding var overwriteRepetitionsMax: Int16? // should be set to nil by the parent view when the selected workoutRoutineSet changes
    
    private var editorRepetitionsMin: Int16? {
        self.overwriteRepetitionsMin ?? self.workoutRoutineSet.minRepetitionsValue
    }
    private var editorRepetitionsMax: Int16? {
        self.overwriteRepetitionsMax ?? self.workoutRoutineSet.maxRepetitionsValue
    }
    
    private var validRepetitions: Bool {
        isValid(minReps: editorRepetitionsMin, maxReps: editorRepetitionsMax)
    }
    
    private func isValid(minReps: Int16?, maxReps: Int16?) -> Bool {
        if let minReps = minReps, let maxReps = maxReps {
            return minReps <= maxReps
        }
        return true
    }
    
    private var keyboardRepetitionsMin: Binding<Double?> {
        Binding(
            get: {
                self.editorRepetitionsMin.map { Double($0) }
            },
            set: { newValue in
                let newValue = newValue.map { Int16(max(min($0, Double(WorkoutSet.MAX_REPETITIONS)), 0)) }
                let maxValue = self.editorRepetitionsMax
                if self.isValid(minReps: newValue, maxReps: maxValue) {
                    self.workoutRoutineSet.minRepetitionsValue = newValue
                    self.workoutRoutineSet.maxRepetitionsValue = maxValue
                    self.overwriteRepetitionsMin = nil
                    self.overwriteRepetitionsMax = nil
                } else {
                    self.overwriteRepetitionsMin = newValue
                }
                self.refresher.refresh()
            }
        )
    }
    
    private var keyboardRepetitionsMax: Binding<Double?> {
        Binding(
            get: {
                self.editorRepetitionsMax.map { Double($0) }
            },
            set: { newValue in
                let newValue = newValue.map { Int16(max(min($0, Double(WorkoutSet.MAX_REPETITIONS)), 0)) }
                let minValue = self.editorRepetitionsMin
                if self.isValid(minReps: minValue, maxReps: newValue) {
                    self.workoutRoutineSet.minRepetitionsValue = minValue
                    self.workoutRoutineSet.maxRepetitionsValue = newValue
                    self.overwriteRepetitionsMin = nil
                    self.overwriteRepetitionsMax = nil
                } else {
                    self.overwriteRepetitionsMax = newValue
                }
                self.refresher.refresh()
            }
        )
    }
    
    private var draggerRepetitionsMin: Binding<Double?> {
        Binding(
            get: {
                self.editorRepetitionsMin.map { Double($0) }
            },
            set: { newValue in
                let newValue = newValue.map { Int16(max(min($0, Double(WorkoutSet.MAX_REPETITIONS)), 0)) }
                let maxValue = self.editorRepetitionsMax
                self.workoutRoutineSet.minRepetitionsValue = newValue
                self.workoutRoutineSet.maxRepetitionsValue = self.isValid(minReps: newValue, maxReps: maxValue) ? maxValue : newValue
                self.overwriteRepetitionsMin = nil
                self.overwriteRepetitionsMax = nil
                self.refresher.refresh()
            }
        )
    }
    
    private var draggerRepetitionsMax: Binding<Double?> {
        Binding(
            get: {
                self.editorRepetitionsMax.map { Double($0) }
            },
            set: { newValue in
                let newValue = newValue.map { Int16(max(min($0, Double(WorkoutSet.MAX_REPETITIONS)), 0)) }
                let minValue = self.editorRepetitionsMin
                self.workoutRoutineSet.maxRepetitionsValue = newValue
                self.workoutRoutineSet.minRepetitionsValue = self.isValid(minReps: minValue, maxReps: newValue) ? minValue : newValue
                self.overwriteRepetitionsMax = nil
                self.overwriteRepetitionsMin = nil
                self.refresher.refresh()
            }
        )
    }
    
    var showNext: Bool
    var onDone: () -> Void = {}
    
    private var repetitionsMinDragger: some View {
        Dragger(
            value: draggerRepetitionsMin,
            unit: "min reps",
            minValue: 0,
            maxValue: Double(WorkoutSet.MAX_REPETITIONS),
            nilPosition: .belowMin,
            showCursor: showKeyboard == .repetitionsMin,
            onTextTapped: {
                if self.showKeyboard == .none {
                    withAnimation {
                        self.showKeyboard = .repetitionsMin
                    }
                } else {
                    self.showKeyboard = .repetitionsMin
                }
            }
        )
        .foregroundColor(validRepetitions ? .primary : .red)
    }
    
    private var repetitionsMaxDragger: some View {
        Dragger(
            value: draggerRepetitionsMax,
            unit: "max reps",
            minValue: 0,
            maxValue: Double(WorkoutSet.MAX_REPETITIONS),
            nilPosition: .belowMin,
            showCursor: showKeyboard == .repetitionsMax,
            onTextTapped: {
                if self.showKeyboard == .none {
                    withAnimation {
                        self.showKeyboard = .repetitionsMax
                    }
                } else {
                    self.showKeyboard = .repetitionsMax
                }
            }
        )
        .foregroundColor(validRepetitions ? .primary : .red)
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
        Button(action: {
            self.onDone()
        }) {
            HStack {
                Spacer()
                Text(showNext ? "Next" : "Ok")
                    .fixedSize()
                    .foregroundColor(.white)
                    .padding(6)
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(.accentColor)
            )
        }
    }
    
    private var moreSheet: some View {
        var title = "Set"
        if let index = workoutRoutineSet.workoutRoutineExercise?.workoutRoutineSets?.index(of: workoutRoutineSet), index != NSNotFound {
            title += " \(index + 1)"
        }
        
        return NavigationView {
            MoreView(workoutRoutineSet: workoutRoutineSet)
                .navigationBarTitle(Text(title), displayMode: .inline)
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
                    value: self.showKeyboard == .repetitionsMin ? self.keyboardRepetitionsMin : self.keyboardRepetitionsMax,
                    alwaysShowDecimalSeparator: .constant(false),
                    minimumFractionDigits: .constant(0),
                    maximumFractionDigits: 0
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
                        if self.showKeyboard == .repetitionsMin {
                            self.showKeyboard = .repetitionsMax
                        } else if self.showKeyboard == .repetitionsMax {
                            self.overwriteRepetitionsMin = nil
                            self.overwriteRepetitionsMax = nil
                            self.onDone()
                            self.showKeyboard = .repetitionsMin
                        }
                    }) {
                        Image(systemName: self.showKeyboard == .repetitionsMin ? "arrow.right" : self.showNext ? "arrow.right" : "checkmark")
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
                    repetitionsMinDragger
                    Divider().frame(height: 44)
                    repetitionsMaxDragger
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
        .drawingGroup() /// fixes visual bug with show/hide animation of this view
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
                            self.showKeyboard = .repetitionsMax
                        }
                    } else if width < 200 {
                        withAnimation {
                            self.showKeyboard = .repetitionsMin
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
    @ObservedObject var workoutRoutineSet: WorkoutRoutineSet
    
    @State private var workoutRoutineSetCommentInput: String? // cannot use ValueHolder here, since it would be recreated on changes
    private var workoutRoutineSetComment: Binding<String> {
        Binding(
            get: {
                self.workoutRoutineSetCommentInput ?? self.workoutRoutineSet.comment ?? ""
            },
            set: { newValue in
                self.workoutRoutineSetCommentInput = newValue
            }
        )
    }
    private func adjustAndSaveWorkoutRoutineSetCommentInput() {
        guard let newValue = workoutRoutineSetCommentInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        workoutRoutineSetCommentInput = newValue
        workoutRoutineSet.comment = newValue.isEmpty ? nil : newValue
        self.workoutRoutineSet.managedObjectContext?.saveOrCrash()
    }

    private func tagButton(tag: WorkoutSetTag) -> some View {
        Button(action: {
            if self.workoutRoutineSet.tagValue == tag {
                self.workoutRoutineSet.tagValue = nil
            } else {
                self.workoutRoutineSet.tagValue = tag
            }
            self.workoutRoutineSet.managedObjectContext?.saveOrCrash()
        }) {
            HStack {
                Image(systemName: "circle.fill")
                    .imageScale(.small)
                    .foregroundColor(tag.color)
                Text(tag.title.capitalized)
                Spacer()
                if self.workoutRoutineSet.tagValue == tag {
                    Image(systemName: "checkmark")
                        .foregroundColor(.secondary)
                }
            }.background(Color.fakeClear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        List {
            Section(header: Text("Tag".uppercased())) {
                ForEach(WorkoutRoutineSet.supportedTags, id: \.self) { tag in
                    self.tagButton(tag: tag)
                }
            }
            
            Section(header: Text("Comment".uppercased())) {
                TextField("Comment", text: workoutRoutineSetComment, onEditingChanged: { isEditingTextField in
                    if !isEditingTextField {
                        self.adjustAndSaveWorkoutRoutineSetCommentInput()
                    }
                })
            }
        }
        .listStyle(GroupedListStyle())
    }
}

#if DEBUG
struct WorkoutRoutineSetEditor_Previews: PreviewProvider {
    static var overwriteRepetitionsMin: Int16? = nil
    static var overwriteRepetitionsMax: Int16? = nil
    
    static var tempRepetitionsMinBinding = Binding<Int16?>(
        get: {
            overwriteRepetitionsMin
        },
        set: { newValue in
            overwriteRepetitionsMin = newValue
        }
    )
    
    static var tempRepetitionsMaxBinding = Binding<Int16?>(
        get: {
            overwriteRepetitionsMax
        },
        set: { newValue in
            overwriteRepetitionsMax = newValue
        }
    )
    
    static var previews: some View {
        Group {
            WorkoutRoutineSetEditor(workoutRoutineSet: MockWorkoutData.metric.workoutRoutineSet, overwriteRepetitionsMin: tempRepetitionsMinBinding, overwriteRepetitionsMax: tempRepetitionsMaxBinding, showNext: false)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
            
            MoreView(workoutRoutineSet: MockWorkoutData.metric.workoutRoutineSet)
                .mockEnvironment(weightUnit: .metric, isPro: true)
                .previewLayout(.sizeThatFits)
                .listStyle(GroupedListStyle())
        }
    }
}
#endif
