//
//  Dragger.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct Dragger : View {
    // public
    @Binding var value: Double
    var numberFormatter: NumberFormatter = NumberFormatter()
    var unit: Text? = nil
    var stepSize: Double = 1 // e.g. if barbell based exercise, set to 2.5
    var minValue: Double? = nil
    var maxValue: Double? = nil
    var showCursor: Bool = false
    var onDragStep: (Double) -> Void = { _ in }
    var onDragCompleted: () -> Void = {}
    var onTextTapped: () -> Void = {}
    
    // private
    @State private var tmpValue: Double? = nil
    @State private var draggerOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var feedbackOnMin: Bool = true
    @State private var feedbackOnMax: Bool = true

    @State private var selectionFeedbackGenerator: UISelectionFeedbackGenerator? = nil
    @State private var minMaxFeedbackGenerator: UINotificationFeedbackGenerator? = nil

    private static let DRAGGER_MOVEMENT: Double = 3 // higher => dragger moves more
    private static let DRAGGER_DELTA_DIVISOR: Double = 40 // higher => less sensible
    
    private var valueString: String {
        numberFormatter.string(from: NSNumber(value: tmpValue ?? value)) ?? ""
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { state in
                self.isDragging = true
                if self.selectionFeedbackGenerator == nil {
                    self.selectionFeedbackGenerator = UISelectionFeedbackGenerator()
                    self.selectionFeedbackGenerator?.prepare()
                }
                let delta = Double(state.startLocation.y - state.location.y)
                if delta > 0 {
                    self.feedbackOnMin = true
                }
                if delta < 0 {
                    self.feedbackOnMax = true
                }
                self.draggerOffset = -CGFloat(delta > 0 ? min(delta, Dragger.DRAGGER_MOVEMENT) : max(delta, -Dragger.DRAGGER_MOVEMENT))
                
                let increment = (delta / Dragger.DRAGGER_DELTA_DIVISOR).rounded(.towardZero) * self.stepSize
                var newValue = self.value + increment
                
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
                if let minValue = self.minValue {
                    if newValue < minValue {
                        newValue = minValue
                        if self.feedbackOnMin {
                            if self.minMaxFeedbackGenerator == nil {
                                self.minMaxFeedbackGenerator = UINotificationFeedbackGenerator()
                                self.minMaxFeedbackGenerator?.prepare()
                            }
                            self.minMaxFeedbackGenerator?.notificationOccurred(.error)
                            self.minMaxFeedbackGenerator?.prepare()
                            self.feedbackOnMin = false
                        }
                    }
                }
                if let maxValue = self.maxValue {
                    if newValue > maxValue {
                        newValue = maxValue
                        if self.feedbackOnMax {
                            if self.minMaxFeedbackGenerator == nil {
                                self.minMaxFeedbackGenerator = UINotificationFeedbackGenerator()
                                self.minMaxFeedbackGenerator?.prepare()
                            }
                            self.minMaxFeedbackGenerator?.notificationOccurred(.error)
                            self.minMaxFeedbackGenerator?.prepare()
                            self.feedbackOnMax = false
                        }
                    }
                }
                
                if self.tmpValue != newValue {
                    if self.tmpValue != nil { // no feedback on init
                        self.selectionFeedbackGenerator?.selectionChanged()
                        self.selectionFeedbackGenerator?.prepare()
                    }
                    self.tmpValue = newValue
                    self.onDragStep(newValue)
                }
            }
            .onEnded { state in
                self.isDragging = false
                self.draggerOffset = 0
                self.selectionFeedbackGenerator = nil
                self.minMaxFeedbackGenerator = nil
                self.feedbackOnMin = true
                self.feedbackOnMax = true
                if let tmpValue = self.tmpValue {
                    self.value = tmpValue
                    self.tmpValue = nil
                    self.onDragCompleted()
                }
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                Text(valueString)
                    .font(Font.body.monospacedDigit())
                if showCursor {
                    RoundedRectangle(cornerRadius: 2, style: .circular)
                        .frame(width: 2, height: 20)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.leading)
            .onTapGesture {
                self.onTextTapped()
            }
            
            Spacer()

            HStack {
                unit
                Image(systemName: "square.grid.4x3.fill")
                    .rotationEffect(Angle(degrees: 90))
                    .offset(y: draggerOffset)
                    .animation(.interactiveSpring())
            }
            .foregroundColor(isDragging ? Color(UIColor.tertiaryLabel): Color.secondary)
            .padding([.leading, .trailing])
            .padding([.top, .bottom], 6)
            .gesture(dragGesture)
            .simultaneousGesture(TapGesture()
                .onEnded {
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(.warning)
                    // TODO: wiggle the dragger
                }
            )
        }
    }
}

#if DEBUG
struct Dragger_Previews : PreviewProvider {
    static var value: Double = 50
    static var previews: some View {
        Dragger(value: Binding(get: { value }, set: { value = $0}), unit: Text("reps"), showCursor: true)
                .previewLayout(.sizeThatFits)
    }
}
#endif
