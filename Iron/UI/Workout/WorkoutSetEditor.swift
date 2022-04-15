//
//  WorkoutSetEditor.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 29.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct WorkoutSetEditor: View {
    let viewModel: ViewModel
    
    @State private var showHelpAlert = false
    
    @State private var showMoreSheet = false
    @State private var showKeyboard: KeyboardType = .none
    @State private var alwaysShowDecimalSeparator = false
    @State private var minimumFractionDigits = 0
    
    private enum KeyboardType {
        case weight
        case repetitions
        case none
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
        textButton(label: Text(viewModel.doneText).foregroundColor(.white), color: .accentColor, action: {
            viewModel.done()
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
    
    
    private var weightDragger: some View {
        Dragger(
            value: viewModel.weight,
            numberFormatter: viewModel.weightNumberFormatter(minimumFractionDigits: minimumFractionDigits, alwaysShowDecimalSeparator: alwaysShowDecimalSeparator),
            unit: viewModel.weightUnitSymbol,
            stepSize: viewModel.weightStepSize,
            minValue: 0,
            maxValue: 99999,
            showCursor: showKeyboard == .weight,
            onDragStep: { _ in
                alwaysShowDecimalSeparator = false
                minimumFractionDigits = viewModel.defaultFractionDigits
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
            value: viewModel.repetitions,
            unit: "reps",
            minValue: 0,
            maxValue: 9999,
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
    
    private var keyboard: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                NumericKeyboard(
                    value: showKeyboard == .weight ? viewModel.weight : viewModel.repetitions,
                    alwaysShowDecimalSeparator: showKeyboard == .weight ? $alwaysShowDecimalSeparator : .constant(false),
                    minimumFractionDigits: showKeyboard == .weight ? $minimumFractionDigits : .constant(0),
                    maximumFractionDigits: showKeyboard == .weight ? viewModel.maximumFractionDigits : 0
                )
                VStack(spacing: 0) {
                    NumericKeyboard.imageActionKeyboardButton(label: Image(systemName: "keyboard.chevron.compact.down"), width: geometry.size.width / 4) {
                        withAnimation { showKeyboard = .none }
                    }
                    
                    NumericKeyboard.imageActionKeyboardButton(label: Image(systemName: "questionmark"), width: geometry.size.width / 4) {
                        showHelpAlert = true
                    }
                    
                    NumericKeyboard.imageActionKeyboardButton(label: Image(systemName: "tag"), width: geometry.size.width / 4) {
                        showMoreSheet = true
                    }
                    
                    Button(action: {
                        NumericKeyboard.playButtonSound()
                        if showKeyboard == .weight {
                            showKeyboard = .repetitions
                        } else if showKeyboard == .repetitions {
                            viewModel.done()
                            showKeyboard = .weight
                        }
                    }) {
                        Image(systemName: showKeyboard == .weight ? "arrow.right" : "checkmark")
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
        VStack {
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
        .gesture(DragGesture()
            .onEnded({ drag in
                let width = drag.predictedEndTranslation.width
                let height = drag.predictedEndTranslation.height
                
                if abs(height) > abs(width) {
                    if height > 200 {
                        withAnimation { showKeyboard = .none }
                    }
                } else {
                    if width > 200 {
                        withAnimation { showKeyboard = .repetitions }
                    } else if width < 200 {
                        withAnimation { showKeyboard = .weight }
                    }
                }
            })
        )
//        .sheet(isPresented: $showMoreSheet) { moreSheet }
        .alert(isPresented: $showHelpAlert) { Alert(title: Text("You can also drag ☰ up and down to adjust the values.")) }
    }
}

import IronData

extension WorkoutSetEditor {
    struct ViewModel {
        @Binding var workoutSet: WorkoutSet
        let exerciseCategory: Exercise.Category
        let localWeightUnit: UnitMass
        var onDone: () -> Void = {}
        
        var weight: Binding<Double?> {
            // TODO: actual local unit
            Binding(
                get: {
                    workoutSet.weight.map { Measurement(value: $0, unit: UnitMass.kilograms).converted(to: localWeightUnit).value }
                },
                set: { newValue in
                    workoutSet.weight = newValue.map { Measurement(value: $0, unit: localWeightUnit).converted(to: .kilograms).value }
                }
            )
        }
        
        var repetitions: Binding<Double?> {
            Binding(
                get: {
                    workoutSet.repetitions.map(Double.init)
                },
                set: { newValue in
                    workoutSet.repetitions = newValue.map(Int.init)
                }
            )
        }
        
        var maximumFractionDigits: Int { 3 }
        
        var defaultFractionDigits: Int {
            if localWeightUnit == UnitMass.kilograms {
                return 1
            } else {
                return 0
            }
        }
        
        var doneText: String { workoutSet.isCompleted ? "Ok" : "Complete Set" }
        
        func done() { onDone() }
        
        var weightStepSize: Double {
            // TODO: let the user configure this for barbell, dumbell and others
            if exerciseCategory == .barbell {
                if localWeightUnit == UnitMass.pounds {
                    return 5
                } else {
                    return Measurement(value: 2.5, unit: UnitMass.kilograms).converted(to: localWeightUnit).value
                }
            } else {
                return 1
            }
        }
        
        var weightUnitSymbol: String {
            localWeightUnit.symbol
        }
        
        func weightNumberFormatter(minimumFractionDigits: Int, alwaysShowDecimalSeparator: Bool) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.allowsFloats = true
            formatter.maximumFractionDigits = maximumFractionDigits
            formatter.minimumFractionDigits = minimumFractionDigits
            formatter.alwaysShowsDecimalSeparator = alwaysShowDecimalSeparator
            return formatter
        }
    }
}

//private struct MoreView: View {
//    @ObservedObject var workoutSet: WorkoutSet
//
//    @State private var activeAlert: AlertType?
//
//    private enum AlertType: Identifiable {
//        case tagInfo
//        case rpeInfo
//
//        var id: Self { self }
//    }
//
//    private func alertFor(type: AlertType) -> Alert {
//        switch type {
//        case .tagInfo:
//            return Alert(title: Text("Mark a set as Failure if you've tried to do more reps but failed."))
//        case .rpeInfo:
//            return Alert(title: Text("The rating of perceived exertion (RPE) is a way to determine and regulate your workout intensity."))
//        }
//    }
//
//    @State private var workoutSetCommentInput: String? // cannot use ValueHolder here, since it would be recreated on changes
//    private var workoutSetComment: Binding<String> {
//        Binding(
//            get: {
//                self.workoutSetCommentInput ?? self.workoutSet.comment ?? ""
//            },
//            set: { newValue in
//                self.workoutSetCommentInput = newValue
//            }
//        )
//    }
//    private func adjustAndSaveWorkoutSetCommentInput() {
//        guard let newValue = workoutSetCommentInput?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
//        workoutSetCommentInput = newValue
//        workoutSet.comment = newValue.isEmpty ? nil : newValue
//        workoutSet.managedObjectContext?.saveOrCrash()
//    }
//
//    private func tagButton(tag: WorkoutSetTag) -> some View {
//        Button(action: {
//            if self.workoutSet.tagValue == tag {
//                self.workoutSet.tagValue = nil
//            } else {
//                self.workoutSet.tagValue = tag
//            }
//        }) {
//            HStack {
//                Image(systemName: "circle.fill")
//                    .imageScale(.small)
//                    .foregroundColor(tag.color)
//                Text(tag.title.capitalized)
//                Spacer()
//                if self.workoutSet.tagValue == tag {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(.secondary)
//                }
//            }.background(Color.fakeClear)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//
//    private func rpeButton(rpe: Double) -> some View {
//        Button(action: {
//            if self.workoutSet.rpeValue == rpe {
//                self.workoutSet.rpeValue = nil
//            } else {
//                self.workoutSet.rpeValue = rpe
//            }
//        }) {
//            HStack {
//                Text(String(format: "%.1f", rpe))
//                Text(RPE.title(rpe) ?? "")
//                    .lineLimit(nil)
//                    .foregroundColor(.secondary)
//                Spacer()
//                if self.workoutSet.rpeValue == rpe {
//                    Image(systemName: "checkmark")
//                        .foregroundColor(.secondary)
//                }
//            }.background(Color.fakeClear)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//
//    var body: some View {
//        List {
//            Section(header:
//                HStack {
//                    Text("Tag".uppercased())
//                    Spacer()
//                    Button(action: {
//                        self.activeAlert = .tagInfo
//                    }) {
//                        Image(systemName: "questionmark.circle")
//                            .foregroundColor(.accentColor)
//                    }
//                }) {
//                ForEach(WorkoutSetTag.allCases, id: \.self) { tag in
//                    self.tagButton(tag: tag)
//                }
//            }
//
//            Section(header: Text("Comment".uppercased())) {
//                TextField("Comment", text: workoutSetComment, onEditingChanged: { isEditingTextField in
//                    if !isEditingTextField {
//                        self.adjustAndSaveWorkoutSetCommentInput()
//                    }
//                })
//            }
//
//            Section(header:
//                HStack {
//                    Text("RPE (Rating of Perceived Exertion)")
//                    Spacer()
//                    Button(action: {
//                        self.activeAlert = .rpeInfo
//                    }) {
//                        Image(systemName: "questionmark.circle")
//                            .foregroundColor(.accentColor)
//                    }
//                }) {
//                ForEach(RPE.allowedValues.reversed(), id: \.self) { rpe in
//                    self.rpeButton(rpe: rpe)
//                }
//            }
//        }
//        .listStyleCompat_InsetGroupedListStyle()
//        .alert(item: $activeAlert) { self.alertFor(type: $0) }
//    }
//}

//struct WorkoutSetEditor_Previews : PreviewProvider {
//    static let database = AppDatabase.random()
//    static var previews: some View {
//        return Group {
//            let workoutSet = try! database.databaseReader.read { db in try WorkoutSet.fetchOne(db) }!
//            let workoutExercise = try! database.databaseReader.read { db in try workoutSet.workoutExercise.fetchOne(db) }!
//            let exercise = try! database.databaseReader.read { db in try workoutExercise.exercise.fetchOne(db) }!
//
//            WorkoutSetEditor(viewModel: .init(
//                database: database,
//                workoutSet: workoutSet,
//                exerciseCategory: exercise.category,
//                localWeightUnit: .kilograms
//            ))
//            .previewDisplayName("Metric")
//            .previewLayout(.sizeThatFits)
//
//            WorkoutSetEditor(viewModel: .init(
//                database: database,
//                workoutSet: workoutSet,
//                exerciseCategory: exercise.category,
//                localWeightUnit: .pounds
//            ))
//            .previewDisplayName("Imperial")
//            .previewLayout(.sizeThatFits)
//        }
//    }
//}
