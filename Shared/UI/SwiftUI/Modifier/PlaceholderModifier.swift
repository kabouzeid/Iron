//
//  PlaceholderModifier.swift
//  Iron
//
//  Created by Karim Abou Zeid on 30.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct PlaceholderModifier<Placeholder>: ViewModifier where Placeholder: View {
    let show: Bool
    let placeholder: Placeholder
    
    init(show: Bool, placeholder: Placeholder) {
        self.show = show
        self.placeholder = placeholder
    }
    
    func body(content: Content) -> some View {
        Group {
            if show {
                placeholder
            } else {
                content
            }
        }
    }
}

extension View {
    func placeholder<Placeholder>(show: Bool, _ placeholder: Placeholder) -> some View where Placeholder : View {
        self.modifier(PlaceholderModifier(show: show, placeholder: placeholder))
    }
}

#if DEBUG
struct PlaceholderModifier_Previews: PreviewProvider {
    static var previews: some View {
        Text("Content")
            .background(Color.red)
            .placeholder(show: true, Text("hi"))
    }
}
#endif
