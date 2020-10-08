//
//  SwiftUISupport.swift
//  Iron
//
//  Created by Karim Abou Zeid on 18.09.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TextCaseNil: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.textCase(nil)
        } else {
            content
        }
    }
}

extension View {
    @ViewBuilder
    func textCaseCompat_nil() -> some View {
        if #available(iOS 14.0, *) {
            textCase(nil)
        } else {
            self
        }
    }
}

extension View {
    @ViewBuilder
    func listStyleCompat_InsetGroupedListStyle() -> some View {
        if #available(iOS 14.0, *) {
            listStyle(InsetGroupedListStyle())
        } else {
            listStyle(GroupedListStyle())
        }
    }
}

extension View {
    @ViewBuilder
    func redacted_compat() -> some View {
        if #available(iOS 14.0, *) {
            redacted(reason: .placeholder)
        }
    }
}

extension View {
    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - condition: The condition to determine if the content should be applied.
    ///   - content: The modifier to apply to the view.
    /// - Returns: The modified view.
    @ViewBuilder func modifier<T: View>(
        if condition: @autoclosure () -> Bool,
        then content: (Self) -> T
    ) -> some View {
        if condition() {
            content(self)
        } else {
            self
        }
    }
    
    /// Applies a modifier to a view conditionally.
    ///
    /// - Parameters:
    ///   - condition: The condition to determine the content to be applied.
    ///   - trueContent: The modifier to apply to the view if the condition passes.
    ///   - falseContent: The modifier to apply to the view if the condition fails.
    /// - Returns: The modified view.
    @ViewBuilder func modifier<TrueContent: View, FalseContent: View>(
        if condition: @autoclosure () -> Bool,
        then trueContent: (Self) -> TrueContent,
        else falseContent: (Self) -> FalseContent
    ) -> some View {
        if condition() {
            trueContent(self)
        } else {
            falseContent(self)
        }
    }
}
