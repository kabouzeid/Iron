import Combine
import GRDB
import GRDBQuery

struct WorkoutRequest: Queryable {
    static var defaultValue: [Workout] { [] }
    
    func publisher(in appDatabase: AppDatabase) -> AnyPublisher<[Workout], Error> {
        ValueObservation
            .tracking(Workout.all().orderedByStart().fetchAll)
            .publisher(in: appDatabase.databaseReader, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
}
