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
        request.predicate = NSPredicate(format: "\(#keyPath(Workout.start)) == self.@max.\(#keyPath(Workout.start))")
        request.propertiesToFetch = ["\(#keyPath(Workout.start))", "\(#keyPath(Workout.end))"]
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
    
    static let dayFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter
    }()
    
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    @ViewBuilder
    func daysView(lastWorkoutDate: Date) -> some View {
        let days = calendar.calendarDays(from: lastWorkoutDate, to: entry.date)
        
        VStack(alignment: .leading) {
            Text(String(days))
                .font(.system(.largeTitle, design: .rounded))
                .foregroundColor(.accentColor)
                +
                Text(" ")
                +
                Text(days == 1 ? "day" : "days")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.accentColor)
            
            Text(lastWorkoutDate, formatter: Self.dayFormatter)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    func workoutView(duration: TimeInterval) -> some View {
        Text(Self.durationFormatter.string(from: duration) ?? "Unknown Duration")
            .foregroundColor(.white)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.accentColor)
            )
    }
    
    var placeholderView: some View {
        Text("No workouts")
            .font(.subheadline)
            .bold()
            .foregroundColor(.secondary)
    }

    var body: some View {
        if let workoutInfo = entry.workoutInfo {
            ZStack {
                Color(.systemBackground)
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Last Workout")
                                .font(.subheadline)
                                .bold()
                            
                            if widgetFamily != .systemSmall {
                                Spacer()
                                
                                // doesn't work every time (iOS 14.1)
//                                Link(destination: DeepLink.url(for: .startWorkout), label: {
//                                    Image(systemName: "plus")
//                                        .foregroundColor(.accentColor)
//                                })
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            daysView(lastWorkoutDate: workoutInfo.start)
                            
                            if widgetFamily != .systemSmall {
                                Spacer()
                                
                                workoutView(duration: workoutInfo.duration)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        } else {
            placeholderView
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
        .supportedFamilies([.systemSmall, .systemMedium])
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
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .environment(\.colorScheme, .dark)
    }
}
