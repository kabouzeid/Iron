//
//  TextSizeDemo.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 22.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

struct TextSizeDemo : View {
    var body: some View {
        VStack {
            Text("large title").font(.largeTitle)
            Text("title").font(.title)
            Text("headline").font(.headline)
            Text("body").font(.body)
            Text("callout").font(.callout)
            Text("sub headline").font(.subheadline)
            Text("footnote").font(.footnote)
            Text("caption").font(.caption)
        }
    }
}

#if DEBUG
struct TextSizeDemo_Previews : PreviewProvider {
    static var previews: some View {
        TextSizeDemo()
    }
}
#endif
