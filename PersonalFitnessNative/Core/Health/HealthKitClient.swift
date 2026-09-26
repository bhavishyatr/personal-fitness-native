import Foundation
import HealthKit

@MainActor
final class HealthKitClient {
    private let store = HKHealthStore()
    private let stepType = HKQuantityType(.stepCount)

    func requestStepAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitClientError.healthDataUnavailable
        }

        try await store.requestAuthorization(
            toShare: [],
            read: [stepType]
        )
    }

    func todayStepCount(now: Date = Date()) async throws -> Int {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitClientError.healthDataUnavailable
        }

        let calendar = Calendar.autoupdatingCurrent
        let startOfDay = calendar.startOfDay(for: now)
        let todayPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        let samples = HKSamplePredicate.quantitySample(
            type: stepType,
            predicate: todayPredicate
        )

        let query = HKStatisticsQueryDescriptor(
            predicate: samples,
            options: .cumulativeSum
        )

        let statistics = try await query.result(for: store)
        let value = statistics?
            .sumQuantity()?
            .doubleValue(for: .count()) ?? 0

        return max(0, Int(value.rounded()))
    }
}

enum HealthKitClientError: LocalizedError {
    case healthDataUnavailable

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Apple Health data is not available on this device."
        }
    }
}
