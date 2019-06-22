//
//  SUISummaryView.swift
//  Sunrise Fit
//
//  Created by Karim Abou Zeid on 19.06.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import CoreData

struct FeedSummaryView : UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<FeedSummaryView>) -> SummaryView {
        let summaryView = SummaryView()
        summaryView.entryCount = 3
        return summaryView
    }
    
    func updateUIView(_ uiView: SummaryView, context: UIViewRepresentableContext<FeedSummaryView>) {
        updateSummary(summaryView: uiView)
        return
    }
    
    private func updateSummary(summaryView: SummaryView) {
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
        let trainingsFromSevenDaysAgo = (try? AppDelegate.instance.persistentContainer.viewContext.fetch(sevenDaysRequest)) ?? []
        let trainingsFromFourteenDaysAgo = (try? AppDelegate.instance.persistentContainer.viewContext.fetch(fourteenDaysRequest)) ?? []
        
        // compute the values
        let valuesSevenDaysAgo = trainingsFromSevenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }
        let valuesFourTeenDaysAgo = trainingsFromFourteenDaysAgo.reduce((0, 0, 0)) { (result, training) -> (TimeInterval, Int, Double) in
            return (result.0 + training.duration, result.1 + training.numberOfCompletedSets, result.2 + training.totalCompletedWeight)
        }
        
        // set the values
        let durationEntry = summaryView.entries[0]
        let setsEntry = summaryView.entries[1]
        let weightEntry = summaryView.entries[2]
        
        durationEntry.title.text = "Duration\nLast 7 Days"
        setsEntry.title.text = "Sets\nLast 7 Days"
        weightEntry.title.text = "Weight\nLast 7 Days"
        
        durationEntry.text.text = Training.durationFormatter.string(from: valuesSevenDaysAgo.0)!
        setsEntry.text.text = "\(valuesSevenDaysAgo.1)"
        weightEntry.text.text = "\(valuesSevenDaysAgo.2.shortStringValue) kg"
        
        var durationPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.0 / valuesFourTeenDaysAgo.0) - 1) * 100)
        durationPercent = abs(durationPercent) < 0.1 ? 0 : durationPercent
        if durationPercent > 0 {
            durationEntry.detail.textColor = UIColor.systemGreen
            durationEntry.detail.text = "+"
        } else if durationPercent < 0 {
            durationEntry.detail.textColor = UIColor.systemRed
            durationEntry.detail.text = ""
        } else {
            durationEntry.detail.textColor = UIColor.darkGray
            durationEntry.detail.text = "+"
        }
        durationEntry.detail.text! += String(format: "%.1f", durationPercent) + "%"
        durationEntry.detail.isHidden = false
        
        var setsPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((Float(valuesSevenDaysAgo.1) / Float(valuesFourTeenDaysAgo.1)) - 1) * 100)
        setsPercent = abs(setsPercent) < 0.1 ? 0 : setsPercent
        if setsPercent > 0 {
            setsEntry.detail.textColor = UIColor.systemGreen
            setsEntry.detail.text = "+"
        } else if setsPercent < 0 {
            setsEntry.detail.textColor = UIColor.systemRed
            setsEntry.detail.text = ""
        } else {
            setsEntry.detail.textColor = UIColor.darkGray
            setsEntry.detail.text = "+"
        }
        setsEntry.detail.text! += String(format: "%.1f", setsPercent) + "%"
        setsEntry.detail.isHidden = false
        
        var weightPercent = valuesFourTeenDaysAgo.0 == 0 ? 0 : (((valuesSevenDaysAgo.2 / valuesFourTeenDaysAgo.2) - 1) * 100)
        weightPercent = abs(weightPercent) < 0.1 ? 0 : weightPercent
        if weightPercent > 0 {
            weightEntry.detail.textColor = UIColor.systemGreen
            weightEntry.detail.text = "+"
        } else if weightPercent < 0 {
            weightEntry.detail.textColor = UIColor.systemRed
            weightEntry.detail.text = ""
        } else {
            weightEntry.detail.textColor = UIColor.darkGray
            weightEntry.detail.text = "+"
        }
        weightEntry.detail.text! += String(format: "%.1f", weightPercent) + "%"
        weightEntry.detail.isHidden = false
    }
}

#if DEBUG
struct SUISummaryView_Previews : PreviewProvider {
    static var previews: some View {
        FeedSummaryView()
    }
}
#endif
