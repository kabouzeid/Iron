//
//  IronWidget.swift
//  IronWidget
//
//  Created by Karim Abou Zeid on 12.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import WidgetKit
import SwiftUI
import WorkoutDataKit
import CoreData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), workoutInfo: WorkoutDataStorage.shared.lastWorkoutInfo)
    }

    func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
        completion(Entry(date: Date(), workoutInfo: WorkoutDataStorage.shared.lastWorkoutInfo))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let date = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        let startOfTomorrow = Calendar.current.startOfDay(for: tomorrow)
        
        completion(Timeline(entries: [Entry(date: date, workoutInfo: WorkoutDataStorage.shared.lastWorkoutInfo)], policy: .after(startOfTomorrow)))
    }
}

private extension WorkoutDataStorage {
    var lastWorkoutInfo: WorkoutInfo? {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.isCurrentWorkout)) != %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [.init(keyPath: \Workout.start, ascending: false)]
        request.propertiesToFetch = ["\(#keyPath(Workout.start))", "\(#keyPath(Workout.end))"]
        request.fetchLimit = 1
        do {
            let workouts = try persistentContainer.viewContext.fetch(request)
            assert(workouts.count <= 1) // the request should only fetch the max
            guard let start = workouts.first?.start, let end = workouts.first?.end else { return nil }
            return WorkoutInfo(start: start, end: end)
        } catch {
            fatalError("Could not execute fetch request for last workout date.")
        }
    }
}

struct Entry: TimelineEntry {
    let date: Date
    let workoutInfo: WorkoutInfo?
}

struct WorkoutInfo {
    let start: Date
    let end: Date
    
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

struct LastWorkoutWidgetEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.calendar) var calendar
    
    var entry: Provider.Entry
    
    private var daysSinceLastWorkout: Int? {
        guard let workoutInfo = entry.workoutInfo else { return nil }
        return calendar.calendarDays(from: workoutInfo.start, to: entry.date)
    }

    var body: some View {
        ZStack {
            Color(red: 255/255, green: 105/255, blue: 0/255, opacity: 1)
            VStack(alignment: .leading) {
                Spacer()
                
                Text("Activity")
                    .font(.headline)
                    .foregroundColor(Color(white: 1, opacity: 0.9))
                
                Spacer()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Last Workout")
                            .font(.subheadline)
                            .foregroundColor(Color.primary.opacity(0.8))
                        //                                .foregroundColor(.secondary)
                        //                                .foregroundColor(Color.primary.opacity(0.7))
                        
                        if let days = daysSinceLastWorkout {
                            Text(String(days))
                                .font(.system(.title3, design: .rounded))
                                .foregroundColor(.primary)
                                +
                                Text(" ")
                                +
                                Text(days == 1 ? "day" : "days")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.primary)
                        } else {
                            Text("-")
                                .font(.system(.title3, design: .rounded))
                        }
                    }
                    .padding(8)
                    
                    Spacer()
                }
                .background(ContainerRelativeShape().fill(Color(.systemBackground).opacity(0.6)))
            }
            .padding()
        }
    }
}

private extension Calendar {
    func calendarDays(from: Date, to: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: from), to: to).day!
    }
}

@main
struct IronWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.lastWorkout.rawValue, provider: Provider()) { entry in
            LastWorkoutWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Last Workout")
        .description("The number of days since the last workout.")
        .supportedFamilies([.systemSmall])
    }
}

struct IronWidget_Previews: PreviewProvider {
    static let start = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    static let end = Calendar.current.date(byAdding: .minute, value: 72, to: start)!
    
    static var previews: some View {
        Group {
            LastWorkoutWidgetEntryView(entry: Entry(date: Date(), workoutInfo: nil))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            LastWorkoutWidgetEntryView(entry: Entry(date: Date(), workoutInfo: WorkoutInfo(start: start, end: end)))
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            LastWorkoutWidgetEntryView(entry: Entry(date: Date(), workoutInfo: WorkoutInfo(start: start, end: end)))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
        }
    }
}
