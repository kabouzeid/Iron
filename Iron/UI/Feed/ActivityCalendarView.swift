//
//  ActivityCalendarView.swift
//  Iron
//
//  Created by Karim Abou Zeid on 05.10.20.
//  Copyright © 2020 Karim Abou Zeid Software. All rights reserved.
//

import SwiftUI
import WorkoutDataKit
import CoreData

struct ActivityCalendarView: View {
    @Environment(\.calendar) var calendar
    
    @EnvironmentObject var exerciseStore: ExerciseStore
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    @FetchRequest(fetchRequest: Workout.fetchRequest()) var workoutHistory // will be overwritten in init()
    
    private static let NUMBER_OF_DAYS = 4 * 7
    
    private static func fetchRequest(calendar: Calendar) -> NSFetchRequest<Workout> {
        let request: NSFetchRequest<Workout> = Workout.fetchRequest()
        request.predicate = NSPredicate(
            format: "\(#keyPath(Workout.isCurrentWorkout)) != %@ AND \(#keyPath(Workout.start)) >= %@",
            NSNumber(booleanLiteral: true),
            calendar.startOfDay(for: calendar.date(byAdding: .day ,value: -(NUMBER_OF_DAYS - 1), to: Date())!) as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Workout.start, ascending: false)]
        return request
    }
    
    init() {
        self._workoutHistory = FetchRequest(fetchRequest: Self.fetchRequest(calendar: calendar))
    }
    
    private var weeks: [[Date?]] {
        calendar.daysByWeek(date: Date(), numberOfDays: Self.NUMBER_OF_DAYS)
    }
    
    private func workoutsOnDay(_ day: Date) -> [Workout] {
        workoutHistory.filter { workout in
            guard let start = workout.start else { return false }
            return calendar.isDate(start, inSameDayAs: day)
        }
    }
    
    let dateFormatter: DateFormatter = {
        let d = DateFormatter()
        d.dateStyle = .short
        d.timeStyle = .short
        return d
    }()
    
    private var activityCalendarDaysByWeek: [[ActivityCalendarDay?]] {
        return weeks.map { week in
            week.map { day in
                day.map {
                    return ActivityCalendarDay(date: $0, workouts: workoutsOnDay($0))
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            ForEach(activityCalendarDaysByWeek, id: \.hashValue) { workoutWeek in
                HStack {
                    ForEach(workoutWeek, id: \.hashValue) { workoutDay in
                        if let workoutDay = workoutDay {
                            ActivityCalendarCell(workoutDay: workoutDay)
                        } else {
                            Circle().foregroundColor(.clear).hidden()
                        }
                    }
                }
            }
        }
        .modifier(if: !entitlementStore.isPro) {
            $0.overlay(UnlockProOverlay(size: .fill).padding())
        }
    }
}

struct ActivityCalendarDay: Hashable {
    let date: Date
    let workouts: [Workout]
}

struct ActivityCalendarHeaderView: View {
    @Environment(\.calendar) var calendar
    
    var weekDays: [String] {
        let weekDaySymbols = calendar.shortStandaloneWeekdaySymbols
        let split = calendar.firstWeekday - 1
        return Array(weekDaySymbols[split..<weekDaySymbols.count] + weekDaySymbols[0..<split])
    }
    
    var body: some View {
        HStack {
            ForEach(weekDays, id: \.self) { weekDay in
                ZStack {
                    Rectangle().frame(height: 0).hidden()
                    Text(weekDay)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct ActivityCalendarCell: View {
    @Environment(\.calendar) var calendar
    
    @EnvironmentObject var entitlementStore: EntitlementStore
    
    @State private var showingWorkout = false
    
    let workoutDay: ActivityCalendarDay
    
    var hasWorkouts: Bool {
        !workoutDay.workouts.isEmpty
    }
    
    var isToday: Bool {
        calendar.isDateInToday(workoutDay.date)
    }
    
    var day: Int {
        calendar.dateComponents([.day], from: workoutDay.date).day!
    }
    
    @ViewBuilder
    var navigationLink: some View {
        if let workout = workoutDay.workouts.first {
            NavigationLink(destination: WorkoutDetailView(workout: workout), isActive: $showingWorkout, label: { EmptyView() }).hidden()
        }
    }
    
    var body: some View {
        Circle()
            .foregroundColor(hasWorkouts ? .accentColor : Color(.systemFill))
            .overlay(
                Text(String(day))
                    .bold()
                    .foregroundColor(hasWorkouts ? .white : .secondary)
            )
            .overlay(
                Group {
                    if isToday {
                        Circle()
                            .strokeBorder(Color(.tertiaryLabel), lineWidth: 3)
                    }
                }
            )
            .modifier(if: entitlementStore.isPro) {
                $0.onTapGesture {
                    self.showingWorkout = true
                }
            }
            .background(navigationLink)
    }
}

private extension Calendar {
    func daysInWeek(of day: Date) -> Int {
        self.range(of: .weekday, in: .weekOfMonth, for: day)!.count
    }

    func weekDayIndex(of day: Date) -> Int {
        let weekDay = self.dateComponents([.weekday], from: day).weekday!
        let shiftedWeekDay = weekDay - self.firstWeekday
        return shiftedWeekDay < 0 ? shiftedWeekDay + daysInWeek(of: day) : shiftedWeekDay
    }

    func weekIndex(of day: Date, referenceWeek: Date) -> Int {
        self.dateComponents([.weekOfYear], from: referenceWeek, to: day).weekOfYear!
    }
    
    func daysByWeek(date: Date, numberOfDays: Int) -> [[Date?]] {
        assert(numberOfDays >= 1)
        
        let days = (0..<numberOfDays).map { i in
            self.startOfDay(for: self.date(byAdding: .day, value: -i, to: date)!)
        }.reversed()

        let startOfFirstWeek = self.date(from: self.dateComponents([.yearForWeekOfYear, .weekOfYear], from: days.first!))!

        var weeks: [[Date?]] = Array(repeating: [], count: self.weekIndex(of: days.last!, referenceWeek: startOfFirstWeek) + 1)
        for day in days {
            let weekIdx = self.weekIndex(of: day, referenceWeek: startOfFirstWeek)
            if weeks[weekIdx].isEmpty {
                weeks[weekIdx] = Array(repeating: nil, count: self.daysInWeek(of: day))
            }
            weeks[weekIdx][self.weekDayIndex(of: day)] = day
        }
        
        return weeks
    }
}

#if DEBUG
struct ActivityCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                VStack(spacing: 16) {
                    Divider()
                    
                    ActivityCalendarHeaderView()
                    
                    Divider()
                    
                    ActivityCalendarView()
                        .frame(height: 250)
                }
            }
            .listStyleCompat_InsetGroupedListStyle()
        }
        .mockEnvironment(weightUnit: .metric, isPro: true)
        .previewLayout(.sizeThatFits)
    }
}
#endif
