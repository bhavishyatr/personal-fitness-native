import Foundation
import Observation

@MainActor
@Observable
final class RunningStore {
    private let healthKit: RunningHealthKitClient

    var workouts: [RunningWorkout] = []
    var isLoading = false
    var message: String?

    init(healthKit: RunningHealthKitClient = RunningHealthKitClient()) {
        self.healthKit = healthKit
    }

    func refresh() async {
        if ProcessInfo.processInfo.arguments.contains("--ui-snapshot") {
            workouts = Self.snapshotWorkouts
            message = nil
            isLoading = false
            return
        }

        isLoading = true
        message = nil
        defer { isLoading = false }

        do {
            try await healthKit.requestAuthorization()
            workouts = try await healthKit.runningWorkouts()
        } catch {
            workouts = []
            message = error.localizedDescription
        }
    }

    func bestRun(near targetMiles: Double) -> RunningDistanceRecord? {
        let tolerance = 0.15

        guard let workout = workouts
            .filter { abs($0.distanceMiles - targetMiles) <= tolerance }
            .min(by: { $0.duration < $1.duration })
        else {
            return nil
        }

        return RunningDistanceRecord(
            targetMiles: targetMiles,
            workout: workout
        )
    }

    var longestRun: RunningWorkout? {
        workouts.max(by: { $0.distanceMiles < $1.distanceMiles })
    }

    var shortestRun: RunningWorkout? {
        workouts.min(by: { $0.distanceMiles < $1.distanceMiles })
    }

    var fastestRun: RunningWorkout? {
        workouts
            .filter { $0.paceSecondsPerMile != nil }
            .min {
                ($0.paceSecondsPerMile ?? .greatestFiniteMagnitude)
                    < ($1.paceSecondsPerMile ?? .greatestFiniteMagnitude)
            }
    }

    static let preview: RunningStore = {
        let store = RunningStore()
        store.workouts = snapshotWorkouts
        return store
    }()

    private static let snapshotWorkouts: [RunningWorkout] = [
        RunningWorkout(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            startDate: Date().addingTimeInterval(-86_400),
            duration: 492,
            distanceMiles: 1.01
        ),
        RunningWorkout(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            startDate: Date().addingTimeInterval(-172_800),
            duration: 1_008,
            distanceMiles: 2.02
        ),
        RunningWorkout(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            startDate: Date().addingTimeInterval(-259_200),
            duration: 1_566,
            distanceMiles: 3.03
        ),
        RunningWorkout(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            startDate: Date().addingTimeInterval(-345_600),
            duration: 2_116,
            distanceMiles: 4.02
        ),
        RunningWorkout(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            startDate: Date().addingTimeInterval(-432_000),
            duration: 3_048,
            distanceMiles: 5.85
        ),
        RunningWorkout(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            startDate: Date().addingTimeInterval(-518_400),
            duration: 402,
            distanceMiles: 0.72
        )
    ]
}
