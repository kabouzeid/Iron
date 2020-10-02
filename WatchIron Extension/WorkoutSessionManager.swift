//
//  WorkoutSessionManager.swift
//  WatchIron Extension
//
//  Created by Karim Abou Zeid on 05.11.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import HealthKit
import Combine
import os.log

class WorkoutSessionManager: NSObject, ObservableObject {
    static let healthStore = HKHealthStore()
    
    var objectWillChange = ObservableObjectPublisher()
    
    var restTimerEnd: Date? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var keepRestTimerRunning: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    var selectedSetText: String? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    private var _burnedCalories: Double? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private var _mostRecentHeartRate: Double? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    private var _startDate: Date? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    var startDate: Date? {
        get {
            _startDate ?? workoutBuilder.startDate
        }
        set {
            assert(newValue != nil)
            if newValue != startDate {
                print("overwriting startDate=\(startDate?.description ?? "nil") with \(newValue?.description ?? "nil")")
                _startDate = newValue
            } else {
                print("keeping startDate=\(startDate?.description ?? "nil") new value would be \(newValue?.description ?? "nil")")
            }
        }
    }
    
    private var _endDate: Date? {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    var endDate: Date? {
        get {
            _endDate ?? workoutBuilder.endDate
        }
        set {
            if newValue != endDate {
                print("overwriting endDate=\(endDate?.description ?? "nil") with \(newValue?.description ?? "nil")")
                _endDate = newValue
            } else {
                print("keeping endDate=\(endDate?.description ?? "nil") new value would be \(newValue?.description ?? "nil")")
            }
        }
    }
    
    private let workoutSession: HKWorkoutSession
    private let workoutBuilder: HKLiveWorkoutBuilder
    
    init(session: HKWorkoutSession) {
        workoutSession = session
        workoutBuilder = session.associatedWorkoutBuilder()
        
        super.init()
        
        workoutSession.delegate = self
        workoutBuilder.delegate = self
    }
    
    // make sure everything that modifies the session or the builder runs on this serial queue
    static let accessQueue = DispatchQueue(label: "com.kabouzeid.workoutsessionmanagerqueue", qos: .userInitiated, target: .global(qos: .userInitiated))
    
    static func perform(_ block: @escaping () -> Void) {
        accessQueue.async {
            block()
        }
    }
    
    static func performAndWait(_ block: () -> Void) {
        accessQueue.sync {
            block()
        }
    }
    
    var state: HKWorkoutSessionState {
        workoutSession.state
    }
    
    var workoutConfiguration: HKWorkoutConfiguration {
        workoutSession.workoutConfiguration
    }
    
    var uuid: UUID? {
        guard let uuidString = workoutBuilder.metadata[HKMetadataKeyExternalUUID] as? String else { return nil }
        return UUID(uuidString: uuidString)
    }
    
    func setUuid(_ uuid: UUID) throws {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        let uuidSemaphore = DispatchSemaphore(value: 0)
        var uuidError: Error?
        workoutBuilder.addMetadata([HKMetadataKeyExternalUUID : uuid.uuidString], completion: { (success, error) in
            defer { uuidSemaphore.signal() }
            if !success {
                uuidError = error ?? NSError()
            }
        })
        uuidSemaphore.wait()
        if let error = uuidError {
            throw error
        }
    }
    
    func setTitle(_ title: String) throws { // there doesn't seem to be a way to undo this
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        let semaphore = DispatchSemaphore(value: 0)
        var _error: Error?
        workoutBuilder.addMetadata([HKMetadataKeyWorkoutBrandName : title], completion: { (success, error) in
            defer { semaphore.signal() }
            if !success {
                _error = error ?? NSError()
            }
        })
        semaphore.wait()
        if let error = _error {
            throw error
        }
    }
    
    func updateStartDate(_ startDate: Date) {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // TODO safe the date in the workout meta data or shared prefs so it can be restored
        self.startDate = startDate
    }
    
    func updateEndDate(_ endDate: Date?) {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // TODO safe the date in the workout meta data or shared prefs so it can be restored
        self.endDate = endDate
    }
    
    func prepare() {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // prepare the workout
        workoutSession.prepare()
    }
    
    /**
     prepare() does not necessarily need to be called before
     */
    func start(start: Date, completion: @escaping (Result<Void, Error>) -> Void) {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        // request permissions
        do {
            try requestWorkoutPermissions().get()
        } catch {
            completion(.failure(error))
            return
        }
        
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        workoutBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: Self.healthStore, workoutConfiguration: workoutSession.workoutConfiguration)
        os_log("Types to collect: %@", type: .debug, workoutBuilder.dataSource?.typesToCollect ?? "nil")
        workoutSession.startActivity(with: start)
        os_log("Beginning collection")
        workoutBuilder.beginCollection(withStart: start, completion: { (success, error) in
            guard success else {
                completion(.failure(error ?? GenericError(description: "Could not begin collection of health samples")))
                return
            }
            completion(.success(()))
        })
    }
    
    func discard() {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        workoutSession.end()
        workoutBuilder.discardWorkout()
    }
    
    func end(end: Date, completion: @escaping (Result<HKWorkout, Error>) -> Void) {
        print(#function)
        dispatchPrecondition(condition: DispatchPredicate.onQueue(Self.accessQueue))
        
        defer {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        
        workoutSession.end()
        
        let endCollectionSemaphore = DispatchSemaphore(value: 0)
        var endCollectionError: Error?
        os_log("Ending collection")
        workoutBuilder.endCollection(withEnd: end, completion: { (success, error) in
            defer { endCollectionSemaphore.signal() }
            if !success {
                endCollectionError = error ?? NSError()
            }
        })
        endCollectionSemaphore.wait()
        if let error = endCollectionError {
            completion(.failure(error))
            return
        }
        os_log("Successfully ended collection", type: .info)
        
        do {
            try self.requestWorkoutPermissions().get()
        } catch {
            completion(.failure(error))
            return
        }
        
        os_log("Finishing workout")
        workoutBuilder.finishWorkout(completion: { (workout, error) in
            guard let workout = workout else {
                completion(.failure(error ?? NSError()))
                return
            }

            if let _startDate = self._startDate, _startDate != workout.startDate {
                print("replacing saved workout because saved workout has startDate \(workout.startDate) but startDate has been updated to \(_startDate)")
                // the start date was updated while the workout was already running
                // replace the saved workout with a copy that has the correct start date
                
                let updatedWorkout = HKWorkout(activityType: workout.workoutActivityType, start: _startDate, end: workout.endDate, workoutEvents: workout.workoutEvents, totalEnergyBurned: workout.totalEnergyBurned, totalDistance: workout.totalDistance, device: workout.device, metadata: workout.metadata)

                Self.healthStore.save(updatedWorkout) { (success, error) in
                    guard success else {
                        completion(.failure(error ?? NSError()))
                        return
                    }
                    Self.healthStore.delete(workout) { (success, error) in
                        guard success else {
                            print(error.debugDescription)
                            return
                        }
                        completion(.success(updatedWorkout))
                    }
                }
            } else {
                completion(.success(workout))
            }
        })
    }
}

extension WorkoutSessionManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
//        print(#function)
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            if collectedTypes.contains(heartRate) {
                mostRecentHeartRate = getMostRecentHeartRate(workoutBuilder: workoutBuilder)
            }
        }

        if let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            if collectedTypes.contains(activeEnergyBurned) {
                burnedCalories = getBurnedCalories(workoutBuilder: workoutBuilder)
            }
        }
    }
}

extension WorkoutSessionManager {
    private func getBurnedCalories(workoutBuilder: HKWorkoutBuilder) -> Double? {
        guard let burnedCalories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return nil }
        return workoutBuilder.statistics(for: burnedCalories)?.sumQuantity()?.doubleValue(for: .kilocalorie())
    }
    
    private func getMostRecentHeartRate(workoutBuilder: HKWorkoutBuilder) -> Double? {
        guard let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        return workoutBuilder.statistics(for: heartRate)?.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
    }
    
    var burnedCalories: Double? {
        get {
            if let burnedCalories = _burnedCalories {
                return burnedCalories
            }
            guard let burnedCalories = getBurnedCalories(workoutBuilder: workoutBuilder) else { return nil }
            _burnedCalories = burnedCalories
            return burnedCalories
        }
        set {
            _burnedCalories = newValue
        }
    }
    
    var mostRecentHeartRate: Double? {
        get {
            if let mostRecentHeartRate = _mostRecentHeartRate {
                return mostRecentHeartRate
            }
            guard let mostRecentHeartRate = getMostRecentHeartRate(workoutBuilder: workoutBuilder) else { return nil }
            _mostRecentHeartRate = mostRecentHeartRate
            return mostRecentHeartRate
        }
        set {
            _mostRecentHeartRate = newValue
        }
    }
}

extension WorkoutSessionManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        os_log("Workout session state changed to %@ from %@", toState.name, fromState.name)
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        os_log("Workout session did fail with error: %@", error.localizedDescription)
        
        // TODO: Notify phone about this, so the phone can clear the watchWorkoutUuid and also save the workout when it finishes. Or display the error on the watch and allow to discard or save.
        WorkoutSessionManager.perform {
            self.discard()
        }
    }
}

// MARK: - Permissions
extension WorkoutSessionManager {
    private static func requestPermissions(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(GenericError(description: "HealthKit is not available on this device.")))
            return
        }
        
        Self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            guard success else {
                completion(.failure(error ?? GenericError(description: "Requesting authorization failed")))
                return
            }
            completion(.success(()))
        }
    }
    
    func requestWorkoutPermissions(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) else { completion(.failure(NSError())); return }
        guard let activeEnergyBurned = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { completion(.failure(NSError())); return }
        let share: Set = [HKObjectType.workoutType()]
        let read = Set([heartRate, activeEnergyBurned])
        
        Self.requestPermissions(toShare: share, read: read, completion: completion)
    }
    
    private func requestWorkoutPermissions() -> Result<Void, Error> {
        let permissionSemaphore = DispatchSemaphore(value: 0)
        var permissionsResult: Result<Void, Error>?
        requestWorkoutPermissions { result in
            defer { permissionSemaphore.signal() }
            permissionsResult = result
        }
        permissionSemaphore.wait()
        precondition(permissionsResult != nil)
        return permissionsResult!
    }
}

extension HKWorkoutSessionState {
    var name: String {
        switch self {
        case .ended:
            return "ended"
        case .notStarted:
            return "not started"
        case .paused:
            return "paused"
        case .prepared:
            return "prepared"
        case .running:
            return "running"
        case .stopped:
            return "stopped"
        @unknown default:
            fatalError()
        }
    }
}
