//
//  Dragger.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 27.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct Dragger : View {
    @Binding var value: Double
    var numberFormatter: NumberFormatter = NumberFormatter()
    var unit: Text? = nil
    var stepSize: Double = 1
    var minValue: Double? = nil
    var maxValue: Double? = nil
    
    var body: some View {
        _Dragger(value: $value, numberFormatter: numberFormatter, unit: unit, stepSize: stepSize, minValue: minValue, maxValue: maxValue, displayValue: value)
    }
}

private struct _Dragger : View {
    // public
    @Binding var value: Double
    var numberFormatter: NumberFormatter = NumberFormatter()
    var unit: Text? = nil
    var stepSize: Double = 1 // e.g. if barbell based exercise, set to 2.5
    var minValue: Double? = nil
    var maxValue: Double? = nil
    
    // private
    @State var displayValue: Double
    @State private var draggerOffset: Length = 0
    @State private var isDragging: Bool = false
    @State private var feedbackOnMin: Bool = true
    @State private var feedbackOnMax: Bool = true

    @State private var selectionFeedbackGenerator: UISelectionFeedbackGenerator? = nil
    @State private var minMaxFeedbackGenerator: UINotificationFeedbackGenerator? = nil

    private static let DRAGGER_MOVEMENT: Double = 3
    private static let DRAGGER_DELTA_DIVISOR: Double = 20 // higher => less sensible
    
    var dragGesture: some Gesture {
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
                self.draggerOffset = -CGFloat(delta > 0 ? min(delta, _Dragger.DRAGGER_MOVEMENT) : max(delta, -_Dragger.DRAGGER_MOVEMENT))
                
                let increment = (delta / _Dragger.DRAGGER_DELTA_DIVISOR).rounded(.towardZero) * self.stepSize
                var newValue = self.value + increment
                if increment != 0 {
                    let remainder = newValue.truncatingRemainder(dividingBy: self.stepSize)
                    newValue -= remainder
                    if increment < 0 {
                        newValue += self.stepSize
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
                
                if self.displayValue != newValue {
                    self.selectionFeedbackGenerator?.selectionChanged()
                    self.selectionFeedbackGenerator?.prepare()
                    self.displayValue = newValue
                }
            }
            .onEnded { state in
                self.isDragging = false
                self.selectionFeedbackGenerator = nil
                self.minMaxFeedbackGenerator = nil
                self.feedbackOnMin = true
                self.feedbackOnMax = true
                self.value = self.displayValue
                self.draggerOffset = 0
        }
    }
    
    var body: some View {
        HStack {
            TextField($displayValue, formatter: numberFormatter)
                .font(Font.body.monospacedDigit())
                .padding([.leading])

            HStack {
                unit
                Image(systemName: "square.grid.4x3.fill")
                    .rotationEffect(Angle(degrees: 90))
                    .offset(y: draggerOffset)
                    .animation(.fluidSpring())
            }
            .foregroundColor(isDragging ? UIColor.tertiaryLabel.swiftUIColor : Color.secondary)
            .padding([.trailing])
            .padding([.top, .bottom], 6)
            .gesture(dragGesture)
        }
    }
}

#if DEBUG
struct MockDragger : View {
    @State var value: Double = 62.5

    var body: some View {
        VStack {
            Dragger(value: $value, unit: Text("kg"))
        }
    }
}
struct Dragger_Previews : PreviewProvider {
    static var previews: some View {
        return MockDragger()
                .previewLayout(.sizeThatFits)
    }
}
#endif
