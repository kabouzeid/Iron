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

class MyCustomStoreType: BindableObject {
    var didChange = PassthroughSubject<Void, Never>()
    
    var weightUnit: WeightUnit {
        get {
            UserDefaults.standard.weightUnit
        }
        set {
            UserDefaults.standard.weightUnit = newValue
            didChange.send()
        }
    }
}

struct FeedBannerView : View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var trainingsDataStore: TrainingsDataStore

    var body: some View {
        BannerView(entries: bannerViewEntries)
            .lineLimit(nil)
    }

    private var bannerViewEntries: [BannerViewEntry] {
        var entries = [BannerViewEntry]()
        // create the fetch requests
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let sevenDaysRequest: NSFetchRequest<Training> = Training.fetchRequest()
        sevenDaysRequest.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@",
                                                 NSNumber(booleanLiteral: true),
                                                 sevenDaysAgo as NSDate)

        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: sevenDaysAgo)!
        let fourteenDaysRequest: NSFetchRequest<Training> = Training.fetchRequest()
        fourteenDaysRequest.predicate = NSPredicate(format: "isCurrentTraining != %@ AND start >= %@ AND start < %@",
                                                    NSNumber(booleanLiteral: true),
                                                    fourteenDaysAgo as NSDate,
                                                    sevenDaysAgo as NSDate)

        // fetch the objects
        let trainingsFromSevenDaysAgo = (try? trainingsDataStore.context.fetch(sevenDaysRequest)) ?? []
        let trainingsFromFourteenDaysAgo = (try? trainingsDataStore.context.fetch(fourteenDaysRequest)) ?? []

        // compute the values
        let valuesSevenDaysAgo = trainingsFromSevenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }
        let valuesFourTeenDaysAgo = trainingsFromFourteenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }

        // set the values

        // Duration
        var durationDetailText: String
        var durationDetailColor: Color
        var durationPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.0 / valuesFourTeenDaysAgo.0) - 1) * 100)
        durationPercent = abs(durationPercent) < 0.1 ? 0 : durationPercent
        if durationPercent > 0 {
            durationDetailColor = Color.green
            durationDetailText = "+"
        } else if durationPercent < 0 {
            durationDetailColor = Color.red
            durationDetailText = ""
        } else {
            durationDetailColor = UIColor.tertiaryLabel.swiftUIColor
            durationDetailText = "+"
        }
        durationDetailText += String(format: "%.1f", durationPercent) + "%"

        entries.append(
            BannerViewEntry(id: 0,
                            title: Text("Duration\nLast 7 Days"),
                            text: Text(Training.durationFormatter.string(from: valuesSevenDaysAgo.0)!),
                            detail: Text(durationDetailText),
                            detailColor: durationDetailColor))

        // Sets
        var setsDetailText: String
        var setsDetailColor: Color
        var setsPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((Float(valuesSevenDaysAgo.1) / Float(valuesFourTeenDaysAgo.1)) - 1) * 100)
        setsPercent = abs(setsPercent) < 0.1 ? 0 : setsPercent
        if setsPercent > 0 {
            setsDetailColor = Color.green
            setsDetailText = "+"
        } else if setsPercent < 0 {
            setsDetailColor = Color.red
            setsDetailText = ""
        } else {
            setsDetailColor = UIColor.tertiaryLabel.swiftUIColor
            setsDetailText = "+"
        }
        setsDetailText += String(format: "%.1f", setsPercent) + "%"
        entries.append(
            BannerViewEntry(id: 1,
                            title: Text("Sets\nLast 7 Days"),
                            text: Text(String(valuesSevenDaysAgo.1)),
                            detail: Text(setsDetailText),
                            detailColor: setsDetailColor))

        // Weight
        var weightDetailText: String
        var weightDetailColor: Color
        var weightPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.2 / valuesFourTeenDaysAgo.2) - 1) * 100)
        weightPercent = abs(weightPercent) < 0.1 ? 0 : weightPercent
        if weightPercent > 0 {
            weightDetailColor = Color.green
            weightDetailText = "+"
        } else if weightPercent < 0 {
            weightDetailColor = Color.red
            weightDetailText = ""
        } else {
            weightDetailColor = UIColor.tertiaryLabel.swiftUIColor
            weightDetailText = "+"
        }
        weightDetailText += String(format: "%.1f", weightPercent) + "%"
        entries.append(
            BannerViewEntry(id: 2,
                            title: Text("Weight\nLast 7 Days"),
                            text: Text(TrainingSet.weightStringFor(weightInKg: valuesSevenDaysAgo.2, unit: settingsStore.weightUnit)),
                            detail: Text(weightDetailText),
                            detailColor: weightDetailColor))
        
        return entries
    }
}

#if DEBUG
struct SUISummaryView_Previews : PreviewProvider {
    static var previews: some View {
        FeedBannerView()
            .environmentObject(mockTrainingsDataStore)
            .environmentObject(mockSettingsStoreMetric)
            .previewLayout(.sizeThatFits)
    }
}
#endif
