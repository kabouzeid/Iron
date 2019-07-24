//
//  NumericKeyboard.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.07.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct NumericKeyboard: View {
    @Binding var value: Double
    @Binding var alwaysShowDecimalSeparator: Bool
    @Binding var minimumFractionDigits: Int
    var maximumFractionDigits: Int
    
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
    
    private func nonZeroFractionDigits(of: Double, upToPlace: Int) -> Int {
        // TODO: use upToPlace instead of hardcoded 3
        if of.truncatingRemainder(dividingBy: 1) == 0{
            return 0
        } else if (of * 10).truncatingRemainder(dividingBy: 1) == 0 {
            return 1
        } else if (of * 100).truncatingRemainder(dividingBy: 1) == 0 {
            return 2
        } else if (of * 1000).truncatingRemainder(dividingBy: 1) == 0 {
            return 3
        }
        print("warning non zero 4")
        return 4
    }
    
    private func prepareNumberFormatter() {
        let actualFractionDigits = nonZeroFractionDigits(of: value, upToPlace: maximumFractionDigits)
        minimumFractionDigits = min(max(minimumFractionDigits, actualFractionDigits), maximumFractionDigits)
        if minimumFractionDigits > 0 {
            alwaysShowDecimalSeparator = true
        }
    }
    
    private func isFractionString(string: String) -> Bool {
        return string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil
    }
    
    private func setValue(string: String?) {
        guard let string = string else { value = 0; return }
        guard let number = self.numberFormatter.number(from: string) else { value = 0; return }
        value = Double(truncating: number)
    }
    
    private func getValueString() -> String? {
        numberFormatter.string(from: value as NSNumber)
    }
    
    private func textKeyboardButton(label: Text, value: String, width: Length) -> some View {
        textActionKeyboardButton(label: label, width: width) {
            self.prepareNumberFormatter()
            guard !self.allowsFloats || self.minimumFractionDigits < self.maximumFractionDigits else { return } // otherwise we might get a bug with rounding
            guard let string = self.getValueString() else { return }
            if self.isFractionString(string: string) {
                self.minimumFractionDigits = self.minimumFractionDigits + 1 // support for 0 after decimal separator
            }
            self.setValue(string: string.appending(value))
        }
    }
    
    private func textActionKeyboardButton(label: Text, width: Length, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
                .padding()
                .foregroundColor(Color.white)
                .frame(width: width)
                .background(UIColor.darkGray.swiftUIColor)
        }
    }
    
    private func imageActionKeyboardButton(label: Image, width: Length, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Text("0") // only used so this button is the same height as the other buttons
                    .padding()
                    .foregroundColor(.clear)
                Image(systemName: "delete.left")
                    .padding()
                    .foregroundColor(.white)
                    .frame(width: width)
            }
            .background(UIColor.darkGray.swiftUIColor)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
//                Text("value: \(self.value), formatted: \(self.numberFormatter.string(from: self.value as NSNumber) ?? "nil")")
//                Text("min fraction digits: \(self.minimumFractionDigits)")
//                Text("alwaysShowSeparator: \(self.alwaysShowDecimalSeparator ? "True" : "False")")
//                Text("is fraction string: \((self.isFractionString(string: self.getValueString() ?? "") ? "yes" : "no"))")
                HStack(spacing: 0) {
                    self.textKeyboardButton(label: Text("1"), value: "1", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("2"), value: "2", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("3"), value: "3", width: geometry.size.width / 3)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 0) {
                    self.textKeyboardButton(label: Text("4"), value: "4", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("5"), value: "5", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("6"), value: "6", width: geometry.size.width / 3)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 0) {
                    self.textKeyboardButton(label: Text("7"), value: "7", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("8"), value: "8", width: geometry.size.width / 3)
                    self.textKeyboardButton(label: Text("9"), value: "9", width: geometry.size.width / 3)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 0) {
                    self.textActionKeyboardButton(label: self.allowsFloats ? Text(".") : Text(""), width: geometry.size.width / 3) {
                        guard self.allowsFloats else { return }
                        self.alwaysShowDecimalSeparator = true
                    }.environment(\.isEnabled, self.allowsFloats)
                    self.textKeyboardButton(label: Text("0"), value: "0", width: geometry.size.width / 3)
                    self.imageActionKeyboardButton(label: Image(systemName: "delete.left"), width: geometry.size.width / 3) {
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
                .buttonStyle(.plain)
            }
            .background(UIColor.gray.swiftUIColor)
            .fixedSize()
        }
        .frame(height: 210) // TODO only temporary (this wont support dynamic type)
    }
}

#if DEBUG
struct NumericKeyboard_Previews: PreviewProvider {
    static var previews: some View {
        NumericKeyboard(value: .constant(15), alwaysShowDecimalSeparator: .constant(false), minimumFractionDigits: .constant(0), maximumFractionDigits: 3)
        .previewLayout(.sizeThatFits)
    }
}
#endif
