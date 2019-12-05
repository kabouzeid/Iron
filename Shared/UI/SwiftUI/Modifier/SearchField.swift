//
//  SearchField.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 01.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import Combine

struct SearchTextFieldStyle: TextFieldStyle {
    @Binding var text: String // for the clear button

    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            configuration
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                    UIApplication.shared.activeSceneKeyWindow?.endEditing(false)
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                })
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).foregroundColor(Color(.systemFill)))
    }
}

#if DEBUG
struct SearchField_Previews : PreviewProvider {
    private struct DemoSearchField: View {
        @State var searchText: String
        var body: some View {
            TextField("Search", text: $searchText)
                .textFieldStyle(SearchTextFieldStyle(text: $searchText))
        }
    }
    
    static var previews: some View {
        VStack {
            DemoSearchField(searchText: "")
            DemoSearchField(searchText: "Test")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
