//
//  FeedBannerView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData
import Combine

struct FeedBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    
    @FetchRequest(fetchRequest: FeedBannerView.sevenDaysFetchRequest) var trainingsFromSevenDaysAgo
    @FetchRequest(fetchRequest: FeedBannerView.fourteenDaysFetchRequest) var trainingsFromFourteenDaysAgo
    
    private static var sevenDaysAgo: Date {
       Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    }
    
    private static var fourteenDaysAgo: Date {
        Calendar.current.date(byAdding: .day, value: -7, to: sevenDaysAgo)!
    }
    
    private static var sevenDaysFetchRequest: NSFetchRequest<Training> {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Training.isCurrentTraining)) != %@ AND \(#keyPath(Training.start)) >= %@", NSNumber(booleanLiteral: true), sevenDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Training.start, ascending: false)]
        return request
    }
    
    private static var fourteenDaysFetchRequest: NSFetchRequest<Training> {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Training.isCurrentTraining)) != %@ AND \(#keyPath(Training.start)) >= %@ AND \(#keyPath(Training.start)) < %@", NSNumber(booleanLiteral: true), fourteenDaysAgo as NSDate, sevenDaysAgo as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Training.start, ascending: false)]
        return request
    }
    
    var body: some View {
        BannerView(entries: bannerViewEntries)
            .lineLimit(2)
    }
    
    private static var percentNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .percent
        return formatter
    }()
    
    private func percentString(of: Double) -> String {
        FeedBannerView.percentNumberFormatter.string(from: of as NSNumber) ?? "\(String(format: "%.1f", of * 100)) %"
    }

    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()

        // compute the values
        let valuesSevenDaysAgo = trainingsFromSevenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.safeDuration, result.1 + (training.numberOfCompletedSets ?? 0), result.2 + (training.totalCompletedWeight ?? 0))
        }
        let valuesFourTeenDaysAgo = trainingsFromFourteenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.safeDuration, result.1 + (training.numberOfCompletedSets ?? 0), result.2 + (training.totalCompletedWeight ?? 0))
        }

        // set the values

        // Duration
        var durationDetailText: String
        var durationDetailColor: Color
        var durationPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (valuesSevenDaysAgo.0 / valuesFourTeenDaysAgo.0) - 1
        durationPercent = abs(durationPercent) < 0.001 ? 0 : durationPercent
        if durationPercent > 0 {
            durationDetailColor = Color.green
            durationDetailText = "+"
        } else if durationPercent < 0 {
            durationDetailColor = Color.red
            durationDetailText = ""
        } else {
            durationDetailColor = Color(UIColor.tertiaryLabel)
            durationDetailText = "+"
        }
        durationDetailText += percentString(of: durationPercent)

        entries.append(
            BannerViewEntry(id: 0,
                            title: Text("Duration\nLast 7 Days"),
                            text: Text(Training.durationFormatter.string(from: valuesSevenDaysAgo.0)!),
                            detail: Text(durationDetailText),
                            detailColor: durationDetailColor))

        // Sets
        var setsDetailText: String
        var setsDetailColor: Color
        var setsPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (Float(valuesSevenDaysAgo.1) / Float(valuesFourTeenDaysAgo.1)) - 1
        setsPercent = abs(setsPercent) < 0.001 ? 0 : setsPercent
        if setsPercent > 0 {
            setsDetailColor = Color.green
            setsDetailText = "+"
        } else if setsPercent < 0 {
            setsDetailColor = Color.red
            setsDetailText = ""
        } else {
            setsDetailColor = Color(UIColor.tertiaryLabel)
            setsDetailText = "+"
        }
        setsDetailText += percentString(of: Double(setsPercent))
        entries.append(
            BannerViewEntry(id: 1,
                            title: Text("Sets\nLast 7 Days"),
                            text: Text(String(valuesSevenDaysAgo.1)),
                            detail: Text(setsDetailText),
                            detailColor: setsDetailColor))

        // Weight
        var weightDetailText: String
        var weightDetailColor: Color
        var weightPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (valuesSevenDaysAgo.2 / valuesFourTeenDaysAgo.2) - 1
        weightPercent = abs(weightPercent) < 0.001 ? 0 : weightPercent
        if weightPercent > 0 {
            weightDetailColor = Color.green
            weightDetailText = "+"
        } else if weightPercent < 0 {
            weightDetailColor = Color.red
            weightDetailText = ""
        } else {
            weightDetailColor = Color(UIColor.tertiaryLabel)
            weightDetailText = "+"
        }
        weightDetailText += percentString(of: weightPercent)
        entries.append(
            BannerViewEntry(id: 2,
                            title: Text("Weight\nLast 7 Days"),
                            text: Text(WeightUnit.format(weight: valuesSevenDaysAgo.2, from: .metric, to: settingsStore.weightUnit)),
                            detail: Text(weightDetailText),
                            detailColor: weightDetailColor))
        
        return entries
    }
}

#if DEBUG
struct SUISummaryView_Previews : PreviewProvider {
    static var previews: some View {
        FeedBannerView()
            .mockEnvironment(weightUnit: .metric, isPro: true)
            .previewLayout(.sizeThatFits)
    }
}
#endif
