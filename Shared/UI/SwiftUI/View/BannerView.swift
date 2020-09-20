//
//  BannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 23.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI

// best in its own section of a grouped List
struct BannerView : View {
    let entries: [BannerViewEntry] // TODO: use @ViewBuilder ?
    
    var body: some View {
        HStack {
            ForEach(entries) { entry in
                Spacer()
                entry.layoutPriority(1)
            }
            if !entries.isEmpty {
                Spacer()
            }
        }
        .padding([.top, .bottom])
    }
}

struct BannerViewEntry : View, Identifiable {
    var id: Int // TODO: get rid of id and use .tag()
    
    var title: Text
    var text: Text

    var detail: Text? = nil
    var detailColor: Color? = nil
    
    var body: some View {
        VStack {
            text
                .font(.compatTitle2)
            if detail != nil {
                detail!
                    .font(.body)
                    .foregroundColor(detailColor ?? Color(UIColor.tertiaryLabel))
            }
            title
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
    }
}

extension Font {
    static var compatTitle2: Font {
        if #available(iOS 14.0, *) {
            return .title2
        } else {
            return Font(UIFont.preferredFont(forTextStyle: .title2))
        }
    }
}

#if DEBUG
struct BannerView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            BannerView(entries: [
                BannerViewEntry(id: 0, title: Text("Duration\nLast 7 Days"), text: Text("2h 14m"), detail: Text("0%")),
                BannerViewEntry(id: 1, title: Text("Repetitions\nLast 7 Days"), text: Text("56"), detail: Text("-5.3%"), detailColor: Color.red),
                BannerViewEntry(id: 2, title: Text("Total Weight\nLast 7 Days"), text: Text("9030 kg"), detail: Text("+20%"), detailColor: Color.green)
                ])
                .lineLimit(nil)

            BannerView(entries: [
                BannerViewEntry(id: 0, title: Text("Duration"), text: Text("2h 14m")),
                BannerViewEntry(id: 1, title: Text("Repetitions"), text: Text("56")),
                BannerViewEntry(id: 2, title: Text("Total Weight"), text: Text("9030 kg"))
                ])
        }
    }
}
#endif
