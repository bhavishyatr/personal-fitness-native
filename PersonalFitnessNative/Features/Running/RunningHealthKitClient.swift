import Foundation
import HealthKit

@MainActor
final class RunningHealthKitClient {
    private let store = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitClientError.healthDataUnavailable
        }

        try await store.requestAuthorization(
            toShare: [],
            read: [workoutType]
        )
    }

    func runningWorkouts() async throws -> [RunningWorkout] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitClientError.healthDataUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let runs = (samples as? [HKWorkout] ?? [])
                    .filter { $0.workoutActivityType == .running }
                    .compactMap { workout -> RunningWorkout? in
                        guard
                            let distance = workout.totalDistance?.doubleValue(for: .mile()),
                            distance > 0
                        else {
                            return nil
                        }

                        return RunningWorkout(
                            id: workout.uuid,
                            startDate: workout.startDate,
                            duration: workout.duration,
                            distanceMiles: distance
                        )
                    }

                continuation.resume(returning: runs)
            }

            store.execute(query)
        }
    }
}
