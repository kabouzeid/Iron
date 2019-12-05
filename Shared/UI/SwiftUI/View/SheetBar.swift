//
//  SheetBar.swift
//  Iron
//
//  Created by Karim Abou Zeid on 14.09.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct SheetBar<Leading, Trailing>: View where Leading: View, Trailing: View {
    let title: String?
    let leading: Leading
    let trailing: Trailing
    
    var body: some View {
        ZStack {
            title.map {
                Text($0).font(.headline)
            }
            HStack {
                leading
                Spacer()
                trailing
            }
        }
    }
}

#if DEBUG
struct SheetBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            SheetBar(title: "Title", leading: Button("Close") {}, trailing: EmptyView()).padding()
            Text("Content View")
        }
    }
}
#endif
