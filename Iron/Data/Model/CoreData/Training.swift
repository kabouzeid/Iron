//
//  Training.swift
//  Rhino Fit
//
//  Created by Karim Abou Zeid on 14.02.18.
//  Copyright © 2018 Karim Abou Zeid Software. All rights reserved.
//

import CoreData
import Combine

class Training: NSManagedObject {
    static var currentTrainingFetchRequest: NSFetchRequest<Training> {
        let request: NSFetchRequest<Training> = Training.fetchRequest()
        request.predicate = NSPredicate(format: "\(#keyPath(Training.isCurrentTraining)) == %@", NSNumber(booleanLiteral: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Training.start, ascending: false)]
        return request
    }

    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()

    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    
    // MARK: Derived properties
    
    var isCompleted: Bool? {
        guard let trainingExercises = trainingExercises else { return nil }
        return !trainingExercises
            .compactMap { $0 as? TrainingExercise }
            .contains { !($0.isCompleted ?? false) }
    }
    
    func displayTitle(in exercises: [Exercise]) -> String {
        if let title = title {
            return title
        }
        let muscleGroups = self.muscleGroups(in: exercises)
        switch muscleGroups.count {
        case 0:
            return "Workout"
        case 1:
            return muscleGroups[0].capitalized
        default:
            return "\(muscleGroups[0].capitalized) & \(muscleGroups[1].capitalized)"
        }
    }
    
    // no duplicate entries, sorted descending by frequency
    func muscleGroups(in exercises: [Exercise]) -> [String] {
        var muscleGroups = [String]()
        
        let trainingExercises = self.trainingExercises?.array as? [TrainingExercise] ?? []
        for trainingExercise in trainingExercises {
            if let exercise = trainingExercise.exercise(in: exercises) {
                // even if there are no sets, add the muscle group at least once
                let factor = max(trainingExercise.trainingSets?.count ?? 1, 1)
                muscleGroups.append(contentsOf: Array(repeating: exercise.muscleGroup, count: factor))
            }
        }
        return muscleGroups.sortedByFrequency().uniqed().reversed()
    }
    
    var duration: TimeInterval? {
        guard let start = start, let end = end else { return nil }
        return end.timeIntervalSince(start)
    }

    var numberOfCompletedSets: Int? {
        trainingExercises?
            .map { $0 as! TrainingExercise }
            .reduce(0, { (count, trainingExercise) -> Int in
                count + (trainingExercise.numberOfCompletedSets ?? 0)
            })
    }
    
    var totalCompletedWeight: Double? {
        trainingExercises?
            .map { $0 as! TrainingExercise }
            .reduce(0, { (weight, trainingExercise) -> Double in
                weight + (trainingExercise.totalCompletedWeight ?? 0)
            })
    }

    private var cancellable: AnyCancellable?
}

// MARK: Safe accessors
extension Training {
    var safeStart: Date {
        get {
            start ?? min(end ?? Date(), Date())
        }
        set {
            precondition(end == nil || newValue <= end!)
            start = newValue
        }
    }
    
    var safeEnd: Date {
        get {
            end ?? max(start ?? Date(), Date())
        }
        set {
            precondition(start == nil || newValue >= start!)
            end = newValue
        }
    }
    
    var safeDuration: TimeInterval {
        safeEnd.timeIntervalSince(safeStart)
    }
}

// MARK: Prepare for finish
extension Training {
    func prepareForFinish() {
        deleteExercisesWhereAllSetsAreUncompleted()
        deleteUncompletedSets()
        // should already be set, but just to be safe
        start = safeStart
        end = safeEnd
    }
    
    // exercises with no sets won't be deleted
    func deleteExercisesWhereAllSetsAreUncompleted() {
        trainingExercises?
            .compactMap { $0 as? TrainingExercise }
            .filter {
                guard let sets = $0.trainingSets?.compactMap({ $0 as? TrainingSet }) else { return false }
                return !sets.isEmpty && !sets.contains { $0.isCompleted }
        }
        .forEach { trainingExercise in
            managedObjectContext?.delete(trainingExercise)
            trainingExercise.training?.removeFromTrainingExercises(trainingExercise)
        }
    }
    
    func deleteUncompletedSets() {
        trainingExercises?
            .compactMap { $0 as? TrainingExercise }
            .compactMap { $0.trainingSets?.compactMap { $0 as? TrainingSet } }
            .flatMap { $0 }
            .filter { !$0.isCompleted }
            .forEach { trainingSet in
                managedObjectContext?.delete(trainingSet)
                trainingSet.trainingExercise?.removeFromTrainingSets(trainingSet)
        }
    }
}

// MARK: Trainings Log
extension Training {
    func logText(in exercises: [Exercise], weightUnit: WeightUnit) -> String? {
        guard let start = start else { return nil }
        guard let duration = duration else { return nil }
        guard let weight = totalCompletedWeight else { return nil }
        let dateFormatter = DateFormatter() // we don't want relative formatting here
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        let dateString = "\(dateFormatter.string(from: start))"
        let durationString = "Duration: \(Self.durationFormatter.string(from: duration)!)"
        let weightString = "Total weight: \(weightUnit.format(weight: weight))"
        
        guard let trainingExercises = trainingExercisesWhereNotAllSetsAreUncompleted else { return nil }
        let exercisesDescription = trainingExercises
            .map { trainingExercise -> String in
                let exerciseTitle = (trainingExercise.exercise(in: exercises)?.title ?? "Unknown exercise")
                guard let trainingSets = trainingExercise.trainingSets else { return exerciseTitle }
                let setsDescription = trainingSets
                    .compactMap { $0 as? TrainingSet }
                    .filter { $0.isCompleted }
                    .map { $0.logTitle(unit: weightUnit) }
                    .joined(separator: "\n")
                guard !setsDescription.isEmpty else { return exerciseTitle }
                return exerciseTitle + "\n" + setsDescription
        }
        .joined(separator: "\n\n")
        return [dateString, durationString, weightString + "\n", exercisesDescription].joined(separator: "\n")
    }
    
    var trainingExercisesWhereNotAllSetsAreUncompleted: [TrainingExercise]? {
        trainingExercises?
            .compactMap { $0 as? TrainingExercise }
            .filter {
                guard let sets = $0.trainingSets?.compactMap({ $0 as? TrainingSet }) else { return false }
                return sets.isEmpty || sets.contains { $0.isCompleted }
        }
    }
}

// MARK: Validation
extension Training {
    override func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateConsistency()
    }
    
    override func validateForInsert() throws {
        try super.validateForInsert()
        try validateConsistency()
    }
    
    func validateConsistency() throws {
        if start == nil {
            throw error(code: 1, message: "start not set")
        }
        
        if !isCurrentTraining, end == nil {
            throw error(code: 2, message: "end not set on finished training")
        }
        
        if let start = start, let end = end, start > end {
            throw error(code: 3, message: "start is greater than end")
        }
        
        if isCurrentTraining, let count = try? managedObjectContext?.count(for: Self.currentTrainingFetchRequest), count > 1 {
            throw error(code: 4, message: "more than one current training")
        }

        if !isCurrentTraining, let isCompleted = isCompleted, !isCompleted {
            throw error(code: 5, message: "training that is not current training is uncompleted")
        }
    }
    
    private func error(code: Int, message: String) -> NSError {
        NSError(domain: "TRAINING_ERROR_DOMAIN", code: code, userInfo: [NSLocalizedFailureReasonErrorKey: message, NSValidationObjectErrorKey: self])
    }
}

// MARK: Observable
extension Training {
    override func awakeFromFetch() {
        super.awakeFromFetch() // important
        initChangeObserver()
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert() // important
        initChangeObserver()
    }
    
    private func initChangeObserver() {
        cancellable = managedObjectContext?.publisher
            .filter { changed in
                changed.contains { managedObject in
                    if let trainingExercise = managedObject as? TrainingExercise {
                        return trainingExercise.training?.objectID == self.objectID
                    }
                    if let trainingSet = managedObject as? TrainingSet {
                        return trainingSet.trainingExercise?.training?.objectID == self.objectID
                    }
                    return managedObject.objectID == self.objectID
                }
        }
        .receive(on: DispatchQueue.main)
        .sink { _ in self.objectWillChange.send() }
    }
}

// MARK: Encodable
extension Training: Encodable {
    private enum CodingKeys: String, CodingKey {
        case title
        case comment
        case start
        case end
        case exercises
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(start, forKey: .start)
        try container.encodeIfPresent(end, forKey: .end)
        try container.encodeIfPresent(trainingExercises?.array.compactMap { $0 as? TrainingExercise }, forKey: .exercises)
    }
}
