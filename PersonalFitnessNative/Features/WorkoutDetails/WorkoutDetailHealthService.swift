import Foundation
import HealthKit
import CoreLocation

@MainActor
final class WorkoutDetailHealthService {
    private let health = HKHealthStore()
    static var readTypes: Set<HKObjectType> {
        [HKObjectType.workoutType(), HKSeriesType.workoutRoute(),
         HKQuantityType(.heartRate), HKQuantityType(.cyclingPower), HKQuantityType(.cyclingCadence)]
    }

    func authorize() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthKitClientError.healthDataUnavailable }
        try await health.requestAuthorization(toShare: [], read: Self.readTypes)
    }

    func workout(id: UUID) async throws -> HKWorkout? {
        let samples = try await samples(type: HKObjectType.workoutType(), predicate: HKQuery.predicateForObject(with: id))
        return samples.first as? HKWorkout
    }

    func readings(_ identifier: HKQuantityTypeIdentifier, workout: HKWorkout) async throws -> [SensorReading] {
        let unit: HKUnit = identifier == .cyclingPower ? .watt() : .count().unitDivided(by: .minute())
        let result = try await samples(type: HKQuantityType(identifier), predicate: HKQuery.predicateForObjects(from: workout))
        return result.compactMap { sample in
            guard let sample = sample as? HKQuantitySample else { return nil }
            let value = sample.quantity.doubleValue(for: unit)
            guard value.isFinite, value >= 0, identifier != .heartRate || value > 0,
                  sample.startDate >= workout.startDate, sample.endDate <= workout.endDate else { return nil }
            return SensorReading(id: sample.uuid, date: sample.startDate, value: value, source: sample.sourceRevision.source.name)
        }.sorted { $0.date < $1.date }
    }

    func routes(workout: HKWorkout) async throws -> [[RoutePoint]] {
        let samples = try await samples(type: HKSeriesType.workoutRoute(), predicate: HKQuery.predicateForObjects(from: workout))
        var result: [[RoutePoint]] = []
        for route in samples.compactMap({ $0 as? HKWorkoutRoute }) {
            let locations: [CLLocation] = try await withCheckedThrowingContinuation { continuation in
                let accumulator = RouteAccumulator(continuation)
                let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                    accumulator.receive(locations ?? [], done: done, error: error)
                }
                health.execute(query)
            }
            // Split at gaps and invalid locations rather than drawing a path across missing data.
            var segment: [RoutePoint] = []
            for location in locations.sorted(by: { $0.timestamp < $1.timestamp }) {
                guard CLLocationCoordinate2DIsValid(location.coordinate), location.horizontalAccuracy >= 0,
                      location.horizontalAccuracy <= 100, location.timestamp >= workout.startDate,
                      location.timestamp <= workout.endDate else {
                    if !segment.isEmpty { result.append(segment); segment = [] }; continue
                }
                if let last = segment.last, location.timestamp.timeIntervalSince(last.date) > 60 {
                    result.append(segment); segment = []
                }
                segment.append(RoutePoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, date: location.timestamp))
            }
            if !segment.isEmpty { result.append(segment) }
        }
        return result
    }

    private func samples(type: HKSampleType, predicate: NSPredicate) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            health.execute(HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples ?? []) }
            })
        }
    }
}

// HealthKit delivers route batches on a background queue. Protect both the buffer and
// continuation so Swift 6 never observes mutable state crossing executors unsafely.
private final class RouteAccumulator: @unchecked Sendable {
    private let lock = NSLock()
    private var locations: [CLLocation] = []
    private var continuation: CheckedContinuation<[CLLocation], Error>?
    init(_ continuation: CheckedContinuation<[CLLocation], Error>) { self.continuation = continuation }
    func receive(_ batch: [CLLocation], done: Bool, error: Error?) {
        lock.lock()
        guard let continuation else { lock.unlock(); return }
        locations.append(contentsOf: batch)
        if error != nil || done {
            self.continuation = nil
            let result = locations
            lock.unlock()
            if let error { continuation.resume(throwing: error) }
            else { continuation.resume(returning: result) }
        } else { lock.unlock() }
    }
}
