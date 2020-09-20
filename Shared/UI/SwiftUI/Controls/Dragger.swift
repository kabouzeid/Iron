//
//  Dragger.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import AVKit

struct Dragger : View {
    // public
    @Binding var value: Double?
    var numberFormatter: NumberFormatter = NumberFormatter()
    var unit: String
    var stepSize: Double = 1 // e.g. if barbell based exercise, set to 2.5
    var minValue: Double? = nil
    var maxValue: Double? = nil
    var nilPosition: NilPosition = .undefined
    var nilPlaceholder: String = ""
    var showCursor: Bool = false
    var onDragStep: (Double?) -> Void = { _ in }
    var onDragCompleted: () -> Void = {}
    var onTextTapped: () -> Void = {}
    
    // private
    @State private var tmpValue: Double? = nil
    @State private var tmpValueInitialized: Bool = false
    @State private var draggerOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var feedbackOnMin: Bool = true
    @State private var feedbackOnMax: Bool = true

    @State private var selectionFeedbackGenerator: UISelectionFeedbackGenerator? = nil
    @State private var minMaxFeedbackGenerator: UINotificationFeedbackGenerator? = nil
    
    enum NilPosition {
        case belowMin
        case aboveMax
        case undefined
    }

    private static let DRAGGER_MOVEMENT: CGFloat = 3 // higher => dragger moves more
    private static let DRAGGER_DELTA_DIVISOR: CGFloat = 40 // higher => less sensible
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { state in
                self.isDragging = true
                if self.selectionFeedbackGenerator == nil {
                    self.selectionFeedbackGenerator = UISelectionFeedbackGenerator()
                    self.selectionFeedbackGenerator?.prepare()
                }
                let delta = state.startLocation.y - state.location.y
                if delta > 0 {
                    self.feedbackOnMin = true
                }
                if delta < 0 {
                    self.feedbackOnMax = true
                }
                self.draggerOffset = -(delta > 0 ? min(delta, Self.DRAGGER_MOVEMENT) : max(delta, -Self.DRAGGER_MOVEMENT))
                
                let steps = (delta / Self.DRAGGER_DELTA_DIVISOR).rounded(.towardZero)
                let increment = steps * CGFloat(self.stepSize)
                var newValue: Double
                switch self.nilPosition {
                case .belowMin:
                    newValue = (self.value ?? ((self.minValue ?? 0) - self.stepSize)) + Double(increment)
                case .aboveMax:
                    newValue = (self.value ?? ((self.maxValue ?? 0) + self.stepSize)) + Double(increment)
                case .undefined:
                    newValue = (self.value ?? 0) + Double(increment)
                }
                
                // handle the case illustrated below
                //
                // Assuming step size of 2.5:
                //
                // 12.5
                // 10
                //  8    <-- Current value
                //  7.5
                //  5
                //  2.5
                if increment != 0 {
                    let remainder = newValue.truncatingRemainder(dividingBy: self.stepSize)
                    if remainder > 0 {
                        newValue -= remainder
                        if increment < 0 {
                            newValue += self.stepSize
                        }
                    }
                    if remainder < 0 {
                        newValue -= remainder
                        if increment > 0 {
                            newValue -= self.stepSize
                        }
                    }
                }
                
                assert(self.minValue ?? -Double.greatestFiniteMagnitude <= self.maxValue ?? Double.greatestFiniteMagnitude)
                var minMaxFeedback = false
                var setNil = false
                if let minValue = self.minValue {
                    if self.nilPosition == .belowMin {
                        let nilValue = minValue - self.stepSize
                        if newValue <= nilValue {
                            setNil = true
                        }
                        if newValue < nilValue {
                            if self.feedbackOnMin {
                                minMaxFeedback = true
                            }
                        }
                    } else if newValue < minValue {
                        newValue = minValue
                        if self.feedbackOnMin {
                            minMaxFeedback = true
                        }
                    }
                }
                if let maxValue = self.maxValue {
                    if self.nilPosition == .aboveMax {
                        let nilValue = maxValue + self.stepSize
                        if newValue >= nilValue {
                            setNil = true
                        }
                        if newValue > nilValue {
                            if self.feedbackOnMax {
                                minMaxFeedback = true
                            }
                        }
                    } else if newValue > maxValue {
                        newValue = maxValue
                        if self.feedbackOnMax {
                            minMaxFeedback = true
                        }
                    }
                }
                
                if minMaxFeedback {
                    if self.minMaxFeedbackGenerator == nil {
                        self.minMaxFeedbackGenerator = UINotificationFeedbackGenerator()
                        self.minMaxFeedbackGenerator?.prepare()
                    }
                    self.minMaxFeedbackGenerator?.notificationOccurred(.error)
                    self.minMaxFeedbackGenerator?.prepare()
                    self.feedbackOnMin = false
                }
                
                let newTmpValue = setNil ? nil : newValue
                if !self.tmpValueInitialized || self.tmpValue != newTmpValue {
                    if self.tmpValueInitialized { // no feedback on init
                        self.selectionFeedbackGenerator?.selectionChanged()
                        self.selectionFeedbackGenerator?.prepare()
                        AudioServicesPlaySystemSound(1157) // picker sound
                    }
                    self.tmpValue = newTmpValue
                    self.tmpValueInitialized = true
                    self.onDragStep(newTmpValue)
                }
            }
            .onEnded { state in
                self.isDragging = false
                self.draggerOffset = 0
                self.selectionFeedbackGenerator = nil
                self.minMaxFeedbackGenerator = nil
                self.feedbackOnMin = true
                self.feedbackOnMax = true
                
                if self.tmpValueInitialized {
                    self.value = self.tmpValue
                    self.tmpValueInitialized = false
                    self.onDragCompleted()
                }
            }
    }
    
    private var valueString: String? {
        (tmpValueInitialized ? tmpValue : value).map { numberFormatter.string(from: NSNumber(value: $0)) ?? "" }
    }
    
    // toggle to wiggle the dragger, the toggling is kind of a hack
    @State private var wiggleDraggerToggle: Bool = false
    
    var body: some View {
        HStack {
            HStack {
                HStack(spacing: 0) {
                    valueString.map {
                        Text($0)
                            .font(Font.body.monospacedDigit())
                            .lineLimit(1)
                    }
                    if showCursor {
                        Cursor()
                    }
                }
                
                Text(unit)
                    .lineLimit(1)
                    .foregroundColor(Color.secondary)
                
                Spacer()
            }
            // This is a hack since tap gesture currently doesn't work on Space that hasn't a background (beta6)
            .overlay(
                Color.fakeClear
                    .onTapGesture {
                        self.onTextTapped()
                    }
            )
//            .animation(.none) // prevents "..." being displayed when number length changes and animation is activated

            Image(systemName: "line.horizontal.3")
                .rotationEffect(Angle(degrees: 0))
                .offset(y: draggerOffset)
                /// disable for now, crashes on iOS 13.1.x production builds but not on iOS 13.2 (built with Xcode 11.2.1 GM)
//                .modifier(WiggleModifier(wiggleToggle: wiggleDraggerToggle, wiggleDistance: Self.DRAGGER_MOVEMENT).animation(.linear(duration: 1)))
                .animation(.interactiveSpring(), value: draggerOffset)
                .foregroundColor(isDragging ? Color.primary : Color.secondary)
//                .padding()
                .imageScale(.large)
                .frame(width: 44, height: 44)
//                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).foregroundColor(Color(.quaternarySystemFill)))
                .gesture(dragGesture)
                .simultaneousGesture(TapGesture()
                    .onEnded {
                        let feedbackGenerator = UINotificationFeedbackGenerator()
                        feedbackGenerator.notificationOccurred(.warning)
                        self.wiggleDraggerToggle.toggle()
                    }
                )
        }
    }
}

// disable for now, crashes on iOS 13.1.x production builds but not on iOS 13.2 (built with Xcode 11.2.1 GM)
//private struct WiggleModifier: AnimatableModifier {
//    var wiggleToggle: Bool // toggle this to animate
//    var wiggleDistance: CGFloat
//
//    private(set) var progress: CGFloat = 0
//
//    var animatableData: CGFloat {
//        get { wiggleToggle ? 1 : 0 }
//        set { wiggleToggle = newValue > 0.5; progress = newValue }
//    }
//
//    func body(content: _ViewModifier_Content<WiggleModifier>) -> some View {
//        content.offset(y: max(min(2*sin(progress * 2 * .pi), 1), -1) * wiggleDistance)
//    }
//}

private struct Cursor: View {
    @State private var blink = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .circular)
            .frame(width: 2, height: 20)
            .foregroundColor(blink ? .clear : .accentColor)
            .onReceive(Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()) { _ in self.blink.toggle() }
    }
}

#if DEBUG
struct Dragger_Previews : PreviewProvider {
    static var value: Double? = 50
    static var previews: some View {
        Dragger(value: Binding(get: { value }, set: { value = $0}), unit: "reps", showCursor: true)
            .previewLayout(.sizeThatFits)
    }
}
#endif
