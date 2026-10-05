import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class PerformanceStore {
    var allSessions: [PerformanceSession] = []
    private(set) var excludedIDs: Set<UUID> = []
    private(set) var recordSeries: [RecordSeries] = []
    var sessions: [PerformanceSession] { InsightMath.eligible(allSessions, excluding: excludedIDs) }
    init() {
        if !ProcessInfo.processInfo.arguments.contains("--ui-snapshot") {
            excludedIDs = Set((UserDefaults.standard.stringArray(forKey: "excluded-performance-sessions") ?? []).compactMap(UUID.init(uuidString:)))
        }
    }
    func isExcluded(_ id: UUID) -> Bool { excludedIDs.contains(id) }
    func setExcluded(_ excluded: Bool, id: UUID) {
        if excluded { excludedIDs.insert(id) } else { excludedIDs.remove(id) }
        if !ProcessInfo.processInfo.arguments.contains("--ui-snapshot") {
            UserDefaults.standard.set(excludedIDs.map(\.uuidString).sorted(), forKey: "excluded-performance-sessions")
        }
        recordSeries = InsightMath.series(sessions)
    }
    var loading = false
    var message: String?
    private var loaded = false
    private let health = HKHealthStore()
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

    func refresh(force: Bool = false) async {
        guard !loading, force || !loaded else { return }
        loading = true
        defer { loading = false }
        if ProcessInfo.processInfo.arguments.contains("--ui-snapshot") {
            allSessions = Self.samples
            recordSeries = InsightMath.series(sessions)
            loaded = true
            return
        }
        do {
            guard HKHealthStore.isHealthDataAvailable() else { throw HealthKitClientError.healthDataUnavailable }
            try await health.requestAuthorization(toShare: [], read: [HKObjectType.workoutType(), distanceType])
            let workouts = try await readWorkouts()
            var next: [PerformanceSession] = []
            var failedSamples = 0
            for workout in workouts {
                guard workout.duration > 0, workout.duration.isFinite else { continue }
                let kind = Self.kind(workout.workoutActivityType)
                let rawDistance = workout.totalDistance?.doubleValue(for: .meter())
                let distance = rawDistance.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
                var session = PerformanceSession(id: workout.uuid, kind: kind, date: workout.startDate,
                    duration: workout.duration, distance: kind.hasDistance ? distance : nil,
                    source: workout.sourceRevision.source.name,
                    environment: (workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool).map { $0 ? "Indoor" : "Outdoor" } ?? "Unspecified")
                session.elevation = (workout.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?.doubleValue(for: .meter())
                if kind == .running, let distance {
                    do { session.points = try await readPoints(workout, total: distance) }
                    catch { failedSamples += 1 }
                }
                next.append(session)
            }
            allSessions = next
            recordSeries = InsightMath.series(sessions)
            loaded = true
            message = failedSamples > 0 ? "Detailed samples could not be loaded for \(failedSamples) runs. Whole-session history is still available. Pull to refresh to retry." : nil
        } catch {
            message = "Could not refresh Apple Health: \(error.localizedDescription)"
        }
    }

    private func readWorkouts() async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: nil, limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples as? [HKWorkout] ?? []) }
            }
            health.execute(query)
        }
    }

    private func readPoints(_ workout: HKWorkout, total: Double) async throws -> [DistancePoint] {
        let samples: [HKQuantitySample] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: distanceType, predicate: HKQuery.predicateForObjects(from: workout),
                limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples as? [HKQuantitySample] ?? []) }
            }
            health.execute(query)
        }
        guard samples.count >= 2 else { return [] }
        var points: [DistancePoint] = []
        var distance = 0.0
        var previousEnd: Date?
        for sample in samples {
            let meters = sample.quantity.doubleValue(for: .meter())
            let interval = sample.endDate.timeIntervalSince(sample.startDate)
            guard meters.isFinite, meters >= 0, interval > 0, interval <= 30,
                  sample.startDate >= workout.startDate, sample.endDate <= workout.endDate else { return [] }
            if let previousEnd {
                let gap = sample.startDate.timeIntervalSince(previousEnd)
                guard gap >= 0, gap <= 30 else { return [] }
                if gap > 0 { points.append(DistancePoint(seconds: sample.startDate.timeIntervalSince(workout.startDate), meters: distance)) }
            } else {
                points.append(DistancePoint(seconds: sample.startDate.timeIntervalSince(workout.startDate), meters: 0))
            }
            distance += meters
            points.append(DistancePoint(seconds: sample.endDate.timeIntervalSince(workout.startDate), meters: distance))
            previousEnd = sample.endDate
        }
        // Do not extrapolate or rescale partial sample coverage to the workout total.
        guard abs(distance - total) / total <= 0.02 else { return [] }
        return points
    }

    private static func kind(_ type: HKWorkoutActivityType) -> ActivityKind {
        switch type {
        case .running: .running
        case .walking: .walking
        case .hiking: .hiking
        case .cycling: .cycling
        case .traditionalStrengthTraining, .functionalStrengthTraining: .strength
        case .swimming: .swimming
        case .rowing: .rowing
        case .yoga: .yoga
        case .pilates: .pilates
        case .highIntensityIntervalTraining: .hiit
        case .badminton: .badminton
        default: .other
        }
    }

    static var samples: [PerformanceSession] {
        var result = ActivityKind.allCases.enumerated().flatMap { index, kind in
            (0..<6).map { n in
                let distance = kind.hasDistance ? Double(n + 1) * PerformanceMath.mile : nil
                let duration = kind.hasDistance ? Double(n + 1) * (520 - Double(n) * 10) : Double(20 + n * 5) * 60
                var session = PerformanceSession(id: UUID(), kind: kind,
                    date: Calendar.current.date(byAdding: .day, value: -(n * 8 + index), to: Date())!,
                    duration: duration, distance: distance, source: "Sample data", environment: "Outdoor")
                if kind == .running, let distance {
                    session.points = (0...200).map { i in
                        let fraction = Double(i) / 200
                        return DistancePoint(seconds: duration * fraction, meters: distance * fraction)
                    }
                }
                return session
            }
        }.sorted { $0.date > $1.date }
        if let run = result.first(where: { $0.kind == .running }) {
            result.append(PerformanceSession(id: UUID(), kind: run.kind, date: run.date.addingTimeInterval(10), duration: run.duration, distance: run.distance, source: "Second sample source", environment: run.environment, points: run.points))
        }
        return result.sorted { $0.date > $1.date }
    }
}
