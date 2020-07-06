//
//  NumericKeyboard.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import AVKit

struct NumericKeyboard: View {
    @Binding var value: Double?
    @Binding var alwaysShowDecimalSeparator: Bool
    @Binding var minimumFractionDigits: Int
    var maximumFractionDigits: Int
    
    static var HEIGHT: CGFloat = 210
    
    private var allowsFloats: Bool {
        maximumFractionDigits > 0
    }
    
    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.allowsFloats = allowsFloats
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = min(minimumFractionDigits, maximumFractionDigits)  // TODO: min() necessary?
        formatter.alwaysShowsDecimalSeparator = allowsFloats ? alwaysShowDecimalSeparator : false
        return formatter
    }
    
    // computes the maximal value of minimumFractionDigits, that produces the same result as the current value of minimumFractionDigits
    private func computeMinimumFractionDigits() -> Int {
        guard let value = value else { return 0 }
        let numberFormatter = self.numberFormatter
        let originalMinimumFractionDigits = numberFormatter.minimumFractionDigits
        if originalMinimumFractionDigits < maximumFractionDigits {
            let originalValueString = numberFormatter.string(from: value as NSNumber)
            for fractionDigits in ((originalMinimumFractionDigits + 1)...maximumFractionDigits).reversed() {
                numberFormatter.minimumFractionDigits = fractionDigits
                if numberFormatter.string(from: value as NSNumber) == originalValueString {
                    return fractionDigits
                }
            }
        }
        return originalMinimumFractionDigits
    }
    
    // needed because minimumFractionDigits can be out of sync if value has been edited from another view
    private func prepareNumberFormatter() {
        minimumFractionDigits = computeMinimumFractionDigits()
        if minimumFractionDigits > 0 {
            alwaysShowDecimalSeparator = true
        }
    }
    
    private func isFractionString(string: String) -> Bool {
        if let decimalSeparator = numberFormatter.locale.decimalSeparator {
            return string.contains(decimalSeparator)
        } else {
            return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
        }
    }
    
    private func setValue(string: String) {
        guard let number = self.numberFormatter.number(from: string) else { value = nil; return }
        value = Double(truncating: number)
    }
    
    private func getValueString() -> String? {
        guard let value = value else { return "" }
        return numberFormatter.string(from: value as NSNumber)
    }
    
    private func textKeyboardButton(label: Text, value: String, width: CGFloat) -> some View {
        Self.textActionKeyboardButton(label: label, width: width) {
            self.prepareNumberFormatter()
            guard !self.allowsFloats || self.minimumFractionDigits < self.maximumFractionDigits else { return } // otherwise we might get a bug with rounding
            guard let string = self.getValueString() else { return }
            if self.isFractionString(string: string) {
                self.minimumFractionDigits = self.minimumFractionDigits + 1 // support for 0 after decimal separator
            }
            self.setValue(string: string.appending(value))
        }
    }
    
    static func playButtonSound() {
        AudioServicesPlaySystemSound(1104)
    }
    
    static func textActionKeyboardButton(label: Text, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: { playButtonSound(); action() }) {
            label
                .foregroundColor(.primary)
                .padding()
                .frame(width: width)
                .background(Color.clear)
        }
    }
    
    static func imageActionKeyboardButton(label: Image, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: { playButtonSound(); action() }) {
            ZStack {
                Text("0") // only used so this button is the same height as the other buttons
                    .padding()
                    .foregroundColor(.clear)
                label
                    .foregroundColor(.primary)
                    .padding()
                    .frame(width: width)
            }
            .background(Color.clear)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    self.textKeyboardButton(label: Text("1"), value: "1", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("4"), value: "4", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("7"), value: "7", width: geometry.size.width / 3)
                    
                    Self.textActionKeyboardButton(label: Text(self.allowsFloats ? (Locale.current.decimalSeparator ?? ".") : " "), width: geometry.size.width / 3) {
                        guard self.allowsFloats else { return }
                        if self.value == nil {
                            self.prepareNumberFormatter()
                            self.value = 0
                        }
                        self.alwaysShowDecimalSeparator = true
                    }.environment(\.isEnabled, self.allowsFloats)
                }
                
                VStack(spacing: 0) {
                    self.textKeyboardButton(label: Text("2"), value: "2", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("5"), value: "5", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("8"), value: "8", width: geometry.size.width / 3)
                    
                    self.textKeyboardButton(label: Text("0"), value: "0", width: geometry.size.width / 3)
                }
                
                VStack(spacing: 0) {
                    self.textKeyboardButton(label: Text("3"), value: "3", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("6"), value: "6", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("9"), value: "9", width: geometry.size.width / 3)
                    
                    Self.imageActionKeyboardButton(label: Image(systemName: "delete.left"), width: geometry.size.width / 3) {
                        self.prepareNumberFormatter()
                        guard let string = self.getValueString() else { return }
                        if !(string.last?.isNumber ?? false) {
                            self.alwaysShowDecimalSeparator = false
                        }
                        if self.isFractionString(string: string) {
                            self.minimumFractionDigits = max(self.minimumFractionDigits - 1, 0)
                        }
                        self.setValue(string: String(string.dropLast()))
                    }
                }
            }
            .fixedSize()
        }
        .frame(height: Self.HEIGHT) // TODO: only temporary because this doesn't support dynamic type size
    }
}

#if DEBUG
struct NumericKeyboard_Previews: PreviewProvider {
    private struct NumericKeyboardPreviewView: View {
        @State private var value: Double? = 15
        @State private var minimumFractionDigits = 0
        @State private var alwaysShowDecimalSeparator = false
        
        private let weightUnit = WeightUnit.metric
        
        private var numberFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.allowsFloats = true
            formatter.maximumFractionDigits = weightUnit.maximumFractionDigits
            formatter.minimumFractionDigits = minimumFractionDigits
            formatter.alwaysShowsDecimalSeparator = alwaysShowDecimalSeparator
            return formatter
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Text("value: \(value?.description ?? "nil"), formatted: \(value.map { numberFormatter.string(from: $0 as NSNumber) ?? "nil" } ?? "")")
                Text("min fraction digits: \(minimumFractionDigits)")
                Text("alwaysShowSeparator: \(alwaysShowDecimalSeparator ? "True" : "False")")
                
                NumericKeyboard(value: $value, alwaysShowDecimalSeparator: $alwaysShowDecimalSeparator, minimumFractionDigits: $minimumFractionDigits, maximumFractionDigits: 3)
            }
        }
    }
    
    static var previews: some View {
//        NumericKeyboardPreviewView()
//            .previewLayout(.sizeThatFits)
        
        NumericKeyboard(value: .constant(0), alwaysShowDecimalSeparator: .constant(false), minimumFractionDigits: .constant(0), maximumFractionDigits: 1)
            .previewLayout(.sizeThatFits)
    }
}
#endif
